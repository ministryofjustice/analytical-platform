##################################################
# AWS
##################################################

data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_iam_roles" "analytical_platform_management_production_runner_roles" {
  provider = aws.analytical-platform-management-production

  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "analytical_platform_data_production_runner_roles" {
  provider = aws.analytical-platform-data-production

  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "analytical_platform_development_runner_roles" {
  provider = aws.analytical-platform-development

  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "analytical_platform_data_engineering_sandbox_sso_administrator_access_roles" {
  provider = aws.analytical-platform-data-engineering-sandbox-a

  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
