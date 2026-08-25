resource "aws_iam_role" "migration_replication" {

  name = "${local.name}-parquet-exports-replication-${var.tags["environment"]}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = [
            "s3.amazonaws.com",
            "batchoperations.s3.amazonaws.com"
          ]
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_s3_bucket" "batch_manifest" {
  # checkov:skip=CKV_AWS_144: Batch Operations manifest bucket does not require cross-region replication
  # checkov:skip=CKV2_AWS_62: Batch Operations manifest bucket does not require event notifications
  # checkov:skip=CKV_AWS_18: Access logging is not required for the temporary Batch Operations manifest bucket

  bucket_prefix = "${local.name}-batch-manifest-${var.tags["environment"]}"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "batch_manifest" {
  bucket = aws_s3_bucket.batch_manifest.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "batch_manifest" {
  bucket = aws_s3_bucket.batch_manifest.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "batch_manifest" {
  bucket = aws_s3_bucket.batch_manifest.id

  rule {
    id     = "delete-old-manifests"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_iam_policy" "migration_replication" {

  name = "${local.name}-parquet-exports-replication-IAM-${var.tags["environment"]}-policy"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:PutInventoryConfiguration"
        ]

        Resource = [
          module.rds_export.parquet_exports_bucket_arn
        ]
      },
      {
        Sid    = "SourceObjectPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:InitiateReplication"
        ]

        Resource = [
          "${module.rds_export.parquet_exports_bucket_arn}/*"
        ]
      },
      {
        Sid    = "DestinationPermissions"
        Effect = "Allow"

        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]

        Resource = [
          "${local.batch_destination_bucket_arn}/*"
        ]
      },
      {
        Sid    = "ManifestAndReportPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]

        Resource = [
          "${aws_s3_bucket.batch_manifest.arn}/*"
        ]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "migration_replication" {

  role       = aws_iam_role.migration_replication.name
  policy_arn = aws_iam_policy.migration_replication.arn
}

resource "aws_s3_bucket_server_side_encryption_configuration" "batch_manifest" {
  bucket = aws_s3_bucket.batch_manifest.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"

      # Use an existing KMS key ARN from this repo/account here
      kms_master_key_id = module.rds_export_kms_dev.key_arn

    }

    bucket_key_enabled = true
  }
}
