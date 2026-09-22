##################################################
# Development
##################################################

module "github_actions_secret_check_iam_policy_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-development
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}

##################################################
# Data Development
##################################################

module "github_actions_secret_check_iam_policy_data_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-data-development
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}

##################################################
# Data Production
##################################################

module "github_actions_secret_check_iam_policy_data_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}

##################################################
# Landing Production
##################################################

module "github_actions_secret_check_iam_policy_landing_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-landing-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}

##################################################
# Management Production
##################################################

module "github_actions_secret_check_iam_policy_management_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for GitHub Actions to check AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check_management_production.json
}

##################################################
# Production
##################################################

module "github_actions_secret_check_iam_policy_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  providers = {
    aws = aws.analytical-platform-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}
