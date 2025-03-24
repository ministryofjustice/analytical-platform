module "development_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.53.0"

  create_role = true

  role_name         = "mojap-data-production-bold-egress-development"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]

  custom_role_policy_arns = [module.development_replication_iam_policy.arn]
}

module "production_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.53.0"

  create_role = true

  role_name         = "mojap-data-production-bold-egress-production"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]

  custom_role_policy_arns = [module.production_replication_iam_policy.arn]
}
