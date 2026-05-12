locals {
  replication_configurations = {
    test = {
      enabled                = true
      source_bucket_name     = "alpha-mojap-ho-data-transfer-test"
      source_bucket_arn      = "arn:aws:s3:::alpha-mojap-ho-data-transfer-test"
      destination_account_id = "591168578261"
      destination_bucket_arn = "arn:aws:s3:::dsa-cdl-police-s3-deposit-cjs-npa"
    }
    production = {
      enabled                = true
      source_bucket_name     = "alpha-mojap-ho-data-transfer"
      source_bucket_arn      = "arn:aws:s3:::alpha-mojap-ho-data-transfer"
      destination_account_id = "314425585946"
      destination_bucket_arn = "arn:aws:s3:::dsa-cdl-police-s3-deposit-cjs-pda"
    }
  }

  enabled_replication_configurations = {
    for k, v in local.replication_configurations : k => v if v.enabled
  }
}
