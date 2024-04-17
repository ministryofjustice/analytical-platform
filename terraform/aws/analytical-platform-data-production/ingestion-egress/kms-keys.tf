module "development_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/mojap-data-production-bold-egress-development"]
  description           = "MoJ AP BOLD Egress - Development"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}

module "production_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "2.2.1"

  aliases               = ["s3/mojap-data-production-bold-egress-production"]
  description           = "MoJ AP BOLD Egress - Production"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}
