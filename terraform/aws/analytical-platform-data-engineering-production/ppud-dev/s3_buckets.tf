moved {
  from = module.rds_export.module.s3-bucket-backup-uploads
  to   = module.s3_bucket_backup_uploads
}

moved {
  from = module.rds_export.module.s3-bucket-parquet-exports
  to   = module.s3_bucket_parquet_exports
}

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

  lifecycle_rule = local.export_bucket_lifecycle_rule
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
  lifecycle_rule = local.export_bucket_lifecycle_rule
  tags           = var.tags
}

locals {
  export_bucket_lifecycle_rule = [{
    id      = "main"
    enabled = "Enabled"
    prefix  = ""
    tags = {
      rule      = "log"
      autoclean = "true"
    }
    transition = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
      },
      {
        days          = 365
        storage_class = "GLACIER"
      }
    ]
    expiration = {
      days = 730
    }
    noncurrent_version_transition = [
      {
        days          = 90
        storage_class = "STANDARD_IA"
      },
      {
        days          = 365
        storage_class = "GLACIER"
      }
    ]
    noncurrent_version_expiration = {
      days = 730
    }
  }]
}