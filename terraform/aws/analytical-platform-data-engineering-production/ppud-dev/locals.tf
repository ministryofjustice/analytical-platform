locals {
  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)

  name = "ppud"

  env = var.tags["environment"]

  batch_destination_bucket_arn = "arn:aws:s3:::ppud-parquet-exports-development-${local.account_ids["digital-prison-reporting-development"]}-eu-west-2-an"

  migration_replication_cutoff_date = "2026-08-20T00:00:00Z"
}
