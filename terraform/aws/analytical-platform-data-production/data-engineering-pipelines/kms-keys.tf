module "mojap_land_dev_datasync_replication_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["s3/mojap-land-dev-datasync-replication"]
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformIngestionDevelopment"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::730335344807:role/datasync-replication"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}

module "mojap_land_datasync_replication_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.1.1"

  aliases               = ["s3/mojap-land-datasync-replication"]
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformIngestionProduction"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::471112983409:role/datasync-replication"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
