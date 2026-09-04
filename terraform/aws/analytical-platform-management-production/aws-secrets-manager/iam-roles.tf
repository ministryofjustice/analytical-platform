module "github_actions_secret_check_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  enable_github_oidc = true
  use_name_prefix    = false

  name = "github-actions-secret-check"

  oidc_wildcard_subjects = [
    "ministryofjustice/YOUR-GITHUB-REPOSITORY:*"
  ]

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy.arn
  }

}
