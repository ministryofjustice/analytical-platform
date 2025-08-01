locals {
  bucket_name             = "mojap-data-production-coat-cur-reports-v2-hourly"
  source_account_id       = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_platform_account_ids.secret_string)["moj-master"]
  source_replication_role = "arn:aws:iam::${local.source_account_id}:role/moj-cur-reports-v2-hourly-replication-role"
}
