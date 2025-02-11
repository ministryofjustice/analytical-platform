module "production_cica_dms_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-cica-dms-ingress-production"]
  description           = "MoJ AP CICA DMS Ibgress - Production"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}
