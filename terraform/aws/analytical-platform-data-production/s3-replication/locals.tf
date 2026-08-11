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

  # Replication configs for the S3 module
  # Dynamic map avoids the Terraform conditional type issue where the replication configuration must be defined even if replication is not enabled
  replication_configs = {
    for k, v in local.replication_configurations : k => {
      role = aws_iam_role.replication[k].arn
      rules = [
        {
          id                        = "${v.source_bucket_name}-replication"
          status                    = "Enabled"
          delete_marker_replication = true

          destination = {
            account_id    = v.destination_account_id
            bucket        = v.destination_bucket_arn
            storage_class = "STANDARD"

            access_control_translation = {
              owner = "Destination"
            }
          }
        }
      ]
    } if v.enabled
  }
}
