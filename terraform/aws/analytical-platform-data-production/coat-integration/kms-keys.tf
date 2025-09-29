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
    },
    {
      sid = "AllowDataSyncRole"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::295814833350:role/coat-datasync"
          ]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
