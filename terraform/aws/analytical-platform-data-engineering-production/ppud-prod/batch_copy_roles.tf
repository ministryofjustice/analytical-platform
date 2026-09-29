# Bucket to store S3 generated manifest and completion report
module "batch_manifest_bucket" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=66bd5c6aa0d0396442f0d4a63642029ff38d2a8a"

  bucket_prefix = "${local.name}-batch-manifest-${local.env}"

  ownership_controls = "BucketOwnerEnforced"

  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "delete-old-manifests-and-reports"
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

# Role S3 Batch Operations assumes to perform the copy
resource "aws_iam_role" "migration_batch_copy" {

  name = "${local.name}-parquet-exports-batch-copy-${local.env}-role"

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

# Permissions for assumed role
resource "aws_iam_policy" "migration_batch_copy" {

  name = "${local.name}-parquet-exports-batch-copy-${local.env}"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        // List or inspect source bucket
        // Create S3 Inventory report to generate batch manifest
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
        // Read source objects
        Sid    = "SourceObjectPermissions"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging"
        ]

        Resource = [
          "${module.rds_export.parquet_exports_bucket_arn}/*"
        ]
      },
      {
        // Write copied objects to destination bucket
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
        // Read and write manifest and report to manifest bucket
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

resource "aws_iam_role_policy_attachment" "migration_batch_copy" {

  role       = aws_iam_role.migration_batch_copy.name
  policy_arn = aws_iam_policy.migration_batch_copy.arn
}
