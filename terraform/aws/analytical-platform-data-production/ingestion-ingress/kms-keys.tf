module "production_cica_dms_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-cica-dms-ingress-production"]
  description           = "MoJ AP CICA DMS Ingress - Production"
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
          identifiers = ["arn:aws:iam::471112983409:role/cica-dms-ingress-production-replication"]
        }
      ]
    }
  ]
  deletion_window_in_days = 7
}

module "datasync_opg_development_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-development-datasync-opg"]
  description           = "MoJ AP OPG DataSync - Development"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7

  policy = jsonencode({
    Statement = [
      {
        Sid    = "AllowS3ReplicationSourceRoleToUseTheKey",
        Effect = "Allow",
        Principal = {
          AWS = local.environment_configurations.development.datasync_opg_replication_iam_role_arn
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

module "datasync_opg_production_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-datasync-opg"]
  description           = "MoJ AP OPG DataSync - Production"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7

  policy = jsonencode({
    Statement = [
      {
        Sid    = "AllowS3ReplicationSourceRoleToUseTheKey",
        Effect = "Allow",
        Principal = {
          AWS = local.environment_configurations.production.datasync_opg_replication_iam_role_arn
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Encrypt"
        ],
        Resource = "*"
      }
    ]
  })
}
