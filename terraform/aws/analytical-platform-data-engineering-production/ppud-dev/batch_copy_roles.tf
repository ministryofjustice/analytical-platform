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
