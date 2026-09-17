##################################################
# Data Development
##################################################

module "github_actions_secret_check_iam_role_data_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-data-development
  }

  create_role       = true
  role_name         = "github-actions-secret-check"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
  ]

  custom_role_policy_arns = [
    module.github_actions_secret_check_iam_policy_data_development.arn
  ]
}

##################################################
# Data Production
##################################################

module "github_actions_secret_check_iam_role_data_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  create_role       = true
  role_name         = "github-actions-secret-check"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
  ]

  custom_role_policy_arns = [
    module.github_actions_secret_check_iam_policy_data_production.arn
  ]
}

##################################################
# Landing Production
##################################################

module "github_actions_secret_check_iam_role_landing_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-landing-production
  }

  create_role       = true
  role_name         = "github-actions-secret-check"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
  ]

  custom_role_policy_arns = [
    module.github_actions_secret_check_iam_policy_landing_production.arn
  ]
}

##################################################
# Production
##################################################

module "github_actions_secret_check_iam_role_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-production
  }

  create_role       = true
  role_name         = "github-actions-secret-check"
  role_requires_mfa = false

  trusted_role_arns = [
    "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
  ]

  custom_role_policy_arns = [
    module.github_actions_secret_check_iam_policy_production.arn
  ]
}
