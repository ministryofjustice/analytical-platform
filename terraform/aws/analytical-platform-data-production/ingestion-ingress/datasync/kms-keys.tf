module "datasync_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-datasync-ingress-${each.key}"]
  description           = "MoJ AP DataSync Ingress - ${title(each.key)}"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformDataSyncIngestion${title(each.key)}"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::471112983409:role/datasync-ingress-${each.key}-replication"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}
