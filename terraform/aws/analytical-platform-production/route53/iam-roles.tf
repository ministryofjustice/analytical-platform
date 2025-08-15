module "analytical_platform_compute_route53_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.1.0"

  name            = "analytical-platform-compute-route53-access"
  use_name_prefix = false

  trust_policy_permissions = {
    trusted_role_arns = {
      actions = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-compute-development"]}:root",
          "arn:aws:iam::${var.account_ids["analytical-platform-compute-test"]}:root",
          "arn:aws:iam::${var.account_ids["analytical-platform-compute-production"]}:root"
        ]
      }]
    }
  }

  policies = {
    analytical_platform_compute_route53_access = module.analytical_platform_compute_route53_access_iam_policy.arn
  }
}
