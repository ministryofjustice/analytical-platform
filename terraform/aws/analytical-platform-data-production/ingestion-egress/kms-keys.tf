module "development_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-bold-egress-development"]
  description           = "MoJ AP BOLD Egress - Development"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}

module "development_kms_eu_west_1_replica" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  providers = {
    aws = aws.eu-west-1
  }

  aliases               = ["s3/mojap-data-production-bold-egress-development-replica"]
  description           = "MoJ AP BOLD Egress - Development - Replica"
  enable_default_policy = true
  create_replica        = true
  primary_key_arn       = module.development_kms.key_arn

  deletion_window_in_days = 7
}

module "production_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  aliases               = ["s3/mojap-data-production-bold-egress-production"]
  description           = "MoJ AP BOLD Egress - Production"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}

module "production_kms_eu_west_1_replica" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.1"

  providers = {
    aws = aws.eu-west-1
  }

  aliases               = ["s3/mojap-data-production-bold-egress-production-replica"]
  description           = "MoJ AP BOLD Egress - Production - Replica"
  enable_default_policy = true
  create_replica        = true
  primary_key_arn       = module.production_kms.key_arn

  deletion_window_in_days = 7
}
