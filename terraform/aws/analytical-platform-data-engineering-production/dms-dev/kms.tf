module "dms_dev_kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["dms/dms-dev"]
  description           = "Used in the HMPPS probation domain to encode secrets and traffic"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    dms_source = {
      grantee_principal = module.dev_dms_oasys.dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = var.tags
}
