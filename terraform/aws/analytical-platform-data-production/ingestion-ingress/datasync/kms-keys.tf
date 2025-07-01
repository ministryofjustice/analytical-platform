module "datasync_opg_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-datasync-opg-ingress-${each.key}"]
  description           = "MoJ AP DataSync OPG Ingress - ${title(each.key)}"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformDataSyncOPGIngestion${title(each.key)}"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-ingestion-${each.key}"]}:role/datasync-opg-ingress-${each.key}-replication"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}

module "datasync_laa_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-datasync-laa-ingress-production"]
  description           = "MoJ AP DataSync LAA Ingress - Production"
  enable_default_policy = true
  key_statements = [
    {
      sid = "AllowAnalyticalPlatformDataSyncLAAIngestionProduction"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/laa-data-analysis-production-replication"]
        }
      ]
    },
    {
      sid = "AllowS3InventoryToUseKMSKey"
      actions = [
        "kms:Encrypt",
        "kms:GenerateDataKey"
      ]
      resources = ["*"]
      effect    = "Allow"
      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]
      condition = [{
        test     = "StringEquals"
        variable = "aws:SourceAccount"
        values   = [var.account_ids["analytical-platform-data-production"]]
      }]
    }
  ]
  deletion_window_in_days = 7
}
