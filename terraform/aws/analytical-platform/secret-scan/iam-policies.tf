##################################################
# Data Development
##################################################

module "github_actions_secret_check_iam_policy_data_development" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

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
  version = "5.60.0"

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
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-landing-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}

##################################################
# Production
##################################################

module "github_actions_secret_check_iam_policy_production" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.60.0"

  providers = {
    aws = aws.analytical-platform-production
  }

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for checking AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json
}
