moved {
  from = module.coat_kms
  to   = module.coat_kms_keys["coat_cur_reports_v2_hourly"]
}

module "coat_kms_keys" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.buckets

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/${each.value.bucket_name}"]
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
          identifiers = [ each.value.source_replication_role ]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
