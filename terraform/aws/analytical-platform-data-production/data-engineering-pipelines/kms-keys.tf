module "mojap_land_datasync_replication_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/mojap-land-datasync-replication"]
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformIngestion"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::730335344807:role/datasync-replication" // analytical-platform-ingestion-development
          ]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
