module "coat_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/${local.bucket_name}"]
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowReplicationRole"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = [local.source_replication_role]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
