locals {
  root_account_id       = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_platform_account_ids.secret_string)["moj-master"]

  buckets = {
    coat_cur_reports_v2_hourly = {
      bucket_name = "mojap-data-production-coat-cur-reports-v2-hourly"
      source_replication_role = "arn:aws:iam::${local.root_account_id}:role/moj-cur-reports-v2-hourly-replication-role"
    }

    coat_cur_reports_v2_hourly_enriched = {
      bucket_name = "mojap-data-production-coat-cur-reports-v2-hourly-enriched"
      source_replication_role = "arn:aws:iam::${var.account_ids["coat-production"]}:role/moj-cur-v2-hourly-enriched-replication-role"
    }
  }
}
