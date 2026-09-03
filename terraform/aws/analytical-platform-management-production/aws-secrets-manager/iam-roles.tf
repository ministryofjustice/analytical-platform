module "github_actions_secret_check_iam_role" {
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