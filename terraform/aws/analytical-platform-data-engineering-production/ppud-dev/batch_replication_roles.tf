resource "aws_iam_role" "migration_replication" {

  name = "${local.name}-parquet-exports-replication-${local.env}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = [
            "batchoperations.s3.amazonaws.com"
          ]
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

module "batch_manifest_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix = "${local.name}-batch-manifest-${local.env}"

  ownership_controls = "BucketOwnerEnforced"

  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "delete-old-manifests"
      enabled = "Enabled"
      prefix  = ""

      expiration = {
        days = 30
      }

      noncurrent_version_expiration = {
        days = 30
      }

      abort_incomplete_multipart_upload_days = 7
    }
  ]

  sse_algorithm = "AES256"

  tags = var.tags

  providers = {
    aws.bucket-replication = aws
  }
}

resource "aws_iam_policy" "migration_replication" {

  name = "${local.name}-parquet-exports-batch-copy-${local.env}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"

        Action = [
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
          "s3:GetObject",
          "s3:GetObjectTagging"
        ]

        Resource = [
          "${module.rds_export.parquet_exports_bucket_arn}/*"
        ]
      },
      {
        Sid    = "DestinationObjectPermissions"
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:PutObjectTagging"
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
          "${module.batch_manifest_bucket.bucket.arn}/*"
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
