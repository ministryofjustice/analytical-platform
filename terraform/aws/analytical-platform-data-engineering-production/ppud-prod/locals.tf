locals {
  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)

  name = "ppud"

  env = var.tags["environment"]

  batch_destination_bucket_arn = "arn:aws:s3:::ppud-parquet-exports-production-${local.account_ids["digital-prison-reporting-production"]}-eu-west-2-an"

  migration_batch_copy_cutoff_date = "2026-09-17T23:59:59Z"

  lifecycle_config_backup_uploads = [{
    id      = "main"
    enabled = "Enabled"
    transition = [
      {
        days          = 60
        storage_class = "STANDARD_IA"
        }, {
        days          = 90
        storage_class = "GLACIER"
        }, {
        days          = 365
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    noncurrent_version_expiration = {
      days = 30
    }
  }]

  lifecycle_config_parquet_exports = [{
    id      = "main"
    enabled = "Enabled"
    transition = [
      {
        days          = 365
        storage_class = "STANDARD_IA"
        }, {
        days          = 465
        storage_class = "GLACIER"
        }, {
        days          = 730
        storage_class = "DEEP_ARCHIVE"
      }
    ]
    noncurrent_version_expiration = {
      days = 30
    }
  }]

}
