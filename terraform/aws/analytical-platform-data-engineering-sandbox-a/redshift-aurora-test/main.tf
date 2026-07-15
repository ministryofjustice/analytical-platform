data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ssm_parameter" "al2023_arm64" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-arm64"
}

# -----------------------------------------------------------------------------
# VPC (with 3 AZs for Redshift Serverless compatibility)
# -----------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name = local.project_name
  environment  = local.environment
  vpc_cidr     = var.vpc_cidr
  tags         = local.tags
}

# -----------------------------------------------------------------------------
# KMS Key for encryption
# -----------------------------------------------------------------------------
module "kms" {
  # checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  deletion_window_in_days = 7
  description             = "KMS key for ${local.project_name}"
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"

  aliases = [local.project_name]

  key_statements = [
    {
      sid = "CloudWatchLogs"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnLike"
          variable = "kms:EncryptionContext:aws:logs:arn"
          values = [
            "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
          ]
        }
      ]
    },
    {
      sid = "SecretsManager"
      actions = [
        "kms:Encrypt*",
        "kms:Decrypt*",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:Describe*"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "Service"
          identifiers = ["secretsmanager.${data.aws_region.current.name}.amazonaws.com"]
        }
      ]
    },
    {
      sid = "RDSExportService"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:CreateGrant",
        "kms:DescribeKey"
      ]
      resources = ["*"]

      principals = [
        {
          type        = "AWS"
          identifiers = [aws_iam_role.rds_export.arn]
        }
      ]
    }
  ]

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Bastion host for Aurora access via SSM
# -----------------------------------------------------------------------------
resource "aws_iam_role" "bastion" {
  name = "${local.project_name}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.project_name}-bastion"
  role = aws_iam_role.bastion.name
}

resource "aws_security_group" "bastion" {
  # checkov:skip=CKV_AWS_23: Bastion host uses SSM with no ingress rules.
  # checkov:skip=CKV_AWS_382: Bastion host needs outbound internet access for SSM.
  name_prefix = "${local.project_name}-bastion-"
  description = "Security group for ${local.project_name} bastion host"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Outbound access for SSM and package installation"
  }

  tags = merge(local.tags, {
    Name = "${local.project_name}-bastion"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "bastion" {
  # checkov:skip=CKV_AWS_126: Detailed monitoring is not required for this test bastion.
  ami                         = data.aws_ssm_parameter.al2023_arm64.value
  ebs_optimized               = true
  instance_type               = var.bastion_instance_type
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  subnet_id                   = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = false

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = merge(local.tags, {
    Name = "${local.project_name}-bastion"
  })
}

# -----------------------------------------------------------------------------
# Aurora PostgreSQL
# -----------------------------------------------------------------------------
module "aurora" {
  source = "./modules/aurora"

  tags = local.tags

  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  vpc_cidr            = var.vpc_cidr

  cluster_name   = "${local.project_name}-aurora"
  engine_version = var.aurora_engine_version
  instance_class = var.aurora_instance_class

  kms_key_arn = module.kms.key_arn
}

# -----------------------------------------------------------------------------
# Redshift Serverless
# -----------------------------------------------------------------------------
module "redshift" {
  source = "./modules/redshift"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  vpc_id           = module.vpc.vpc_id
  database_subnets = module.vpc.database_subnet_ids
  vpc_cidr         = var.vpc_cidr

  kms_key_arn = module.kms.key_arn

  price_performance_level = var.redshift_price_performance_level
}

# -----------------------------------------------------------------------------
# Aurora Snapshot Export to S3
#
# Export Aurora snapshots to S3 as Parquet files.
# See: https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-export-snapshot.html
#
# Usage (AWS CLI):
#   aws rds start-export-task \
#     --export-task-identifier my-export \
#     --source-arn <snapshot-arn> \
#     --s3-bucket-name <bucket-name> \
#     --iam-role-arn <role-arn> \
#     --kms-key-id <kms-key-arn>
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "aurora_export" {
  # checkov:skip=CKV_AWS_144:Cross-region replication not required for test environment
  # checkov:skip=CKV2_AWS_62:Event notifications not required for snapshot exports
  # checkov:skip=CKV_AWS_18:Access logging not required for test environment
  bucket = "${local.project_name}-aurora-export"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "aurora_export" {
  bucket = aws_s3_bucket.aurora_export.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aurora_export" {
  bucket = aws_s3_bucket.aurora_export.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = module.kms.key_arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "aurora_export" {
  bucket = aws_s3_bucket.aurora_export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "aurora_export" {
  bucket = aws_s3_bucket.aurora_export.id

  rule {
    id     = "expire-old-exports"
    status = "Enabled"

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_iam_role" "rds_export" {
  name = "${local.project_name}-rds-export"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "rds_export_s3" {
  name = "s3-export-access"
  role = aws_iam_role.rds_export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ExportToS3"
        Effect = "Allow"
        Action = [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:DeleteObject*",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.aurora_export.arn,
          "${aws_s3_bucket.aurora_export.arn}/*"
        ]
      }
    ]
  })
}
