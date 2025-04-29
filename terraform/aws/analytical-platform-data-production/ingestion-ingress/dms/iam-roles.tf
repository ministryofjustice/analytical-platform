module "dms_ingress_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.55.0"

  create_role = true

  role_name         = "mojap-data-production-dms-ingress-${each.key}"
  role_requires_mfa = false

  trusted_role_services = ["s3.amazonaws.com"]
  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-ingestion-${each.key}"]}:role/tariff-${each.key}-metadata-generator"
  ]

  custom_role_policy_arns = [module.dms_ingress_iam_policy[each.key].arn]
}
