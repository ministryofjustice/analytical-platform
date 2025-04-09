module "dms_test_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["dms/hmpps-test"]
  description           = "Used in the hmpps probation to encode secrets"
  enable_default_policy = true

  deletion_window_in_days = 7

  # Grants
  grants = {
    dms_source = {
      grantee_principal = module.test_dms_implementation.dms_source_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = local.tags
}