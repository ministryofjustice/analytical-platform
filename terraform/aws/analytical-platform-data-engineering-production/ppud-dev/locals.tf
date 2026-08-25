locals {
  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)

  name = "ppud"

  env = var.tags["environment"]

  batch_destination_bucket_name = "ppud-parquet-exports-dev-20251002161459329900000002"

  batch_destination_bucket_arn = "arn:aws:s3:::ppud-parquet-exports-dev-20251002161459329900000002"

  migration_replication_cutoff_date = "2026-08-20T00:00:00Z"
}
