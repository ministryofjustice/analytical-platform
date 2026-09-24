##################################################
# Development
##################################################

module "github_actions_secret_check_iam_role_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-development
  }

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_development.arn
  }
}

##################################################
# Data Development
##################################################

module "github_actions_secret_check_iam_role_data_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-data-development
  }

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_data_development.arn
  }
}

##################################################
# Data Production
##################################################

module "github_actions_secret_check_iam_role_data_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_data_production.arn
  }
}

##################################################
# Landing Production
##################################################

module "github_actions_secret_check_iam_role_landing_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-landing-production
  }

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_landing_production.arn
  }
}

##################################################
# Management Production
##################################################

module "github_actions_secret_check_iam_role_management_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  name               = "github-actions-secret-check"
  use_name_prefix    = false
  enable_github_oidc = true

  oidc_wildcard_subjects = [
    "ministryofjustice/analytical-platform:*"
  ]

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_management_production.arn
  }
}

##################################################
# Production
##################################################

module "github_actions_secret_check_iam_role_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-production
  }

  name            = "github-actions-secret-check"
  use_name_prefix = false

  trust_policy_permissions = {
    TrustManagementProductionRole = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type = "AWS"
        identifiers = [
          "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/github-actions-secret-check"
        ]
      }]
    }
  }

  policies = {
    github_actions_secret_check = module.github_actions_secret_check_iam_policy_production.arn
  }
}
