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

data "aws_iam_roles" "self-hosted-runner-roles" {
  provider   = aws.analytical-platform-management-production
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "data-self-hosted-runner-roles" {
  provider   = aws.analytical-platform-data-production
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "dev-self-hosted-runner-roles" {
  provider   = aws.analytical-platform-development
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "analytical-platform-sso-admin-access-sandbox" {
  provider    = aws.analytical-platform-data-engineering-sandbox-a
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
