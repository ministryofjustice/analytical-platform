module "analytical_platform_compute_route53_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.53.0"

  create_role = true

  role_name         = "analytical-platform-compute-route53-access"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-compute-development"]}:root",
    "arn:aws:iam::${var.account_ids["analytical-platform-compute-test"]}:root",
    "arn:aws:iam::${var.account_ids["analytical-platform-compute-production"]}:root",
  ]

  custom_role_policy_arns = [module.analytical_platform_compute_route53_access_iam_policy.arn]
}
