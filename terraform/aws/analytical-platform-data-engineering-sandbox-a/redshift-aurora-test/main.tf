data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# VPC
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
    }
  ]

  tags = local.tags
}

# -----------------------------------------------------------------------------
# Aurora PostgreSQL
# -----------------------------------------------------------------------------
module "aurora" {
  source = "./modules/aurora"

  project_name = local.project_name
  environment  = local.environment
  tags         = local.tags

  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  vpc_cidr            = var.vpc_cidr

  cluster_name   = "${local.project_name}-aurora"
  engine_version = var.aurora_engine_version
  instance_class = var.aurora_instance_class

  kms_key_arn = module.kms.key_arn
}
