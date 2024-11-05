module "mojap_cadet_production_replication_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.47.1"

  create_role = true

  role_name         = "mojap-data-production-cadet-to-apc-production-replication"
  role_requires_mfa = false

  trusted_role_services = [
    "s3.amazonaws.com",
    "batchoperations.s3.amazonaws.com"
  ]

  custom_role_policy_arns = [
    module.mojap_cadet_production_replication_iam_policy.arn,
    module.mojap_cadet_production_replication_to_dev_iam_policy.arn
  ]
}
