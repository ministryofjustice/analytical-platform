module "mojap_national_security_data_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["s3/mojap-data-production-national-security-data"]
  description           = "National Security Data KMS Key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
