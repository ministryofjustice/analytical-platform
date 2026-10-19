# Backup .bak uploads bucket with sensible defaults
#trivy:ignore:AVD-AWS-0089 Bucket logging not required.
module "s3_bucket_backup_uploads" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=4f72896323ec7f06e293f1f75732549b3248f841" #v11.1.1

  bucket_prefix      = "${local.name}-backup-uploads-${local.env}-"
  bucket_namespace   = "global"
  versioning_enabled = true

  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm = "AES256"

  lifecycle_rule = local.lifecycle_config_backup_uploads
  tags           = var.tags
}

module "s3_bucket_parquet_exports" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=4f72896323ec7f06e293f1f75732549b3248f841"

  bucket_prefix      = "${local.name}-parquet-exports-${local.env}-"
  bucket_namespace   = "global"
  versioning_enabled = true

  ownership_controls  = "BucketOwnerEnforced"
  replication_enabled = false

  providers = {
    aws.bucket-replication = aws
  }

  sse_algorithm  = "AES256"
  lifecycle_rule = local.lifecycle_config_parquet_exports
  tags           = var.tags
}
