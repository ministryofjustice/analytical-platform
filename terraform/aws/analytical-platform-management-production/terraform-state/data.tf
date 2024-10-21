data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_iam_roles" "analytical_platform_team_access_role" {
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "data_engineering_team_access_role_data_engineering_production_data_eng" {
  provider = aws.analytical-platform-data-engineering-production

  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "data_engineering_team_access_role_data_engineering_sandbox_a_admin" {
  provider = aws.analytical-platform-data-engineering-sandbox-a

  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "data_engineering_team_access_role_data_engineering_sandbox_a_data_eng" {
  provider = aws.analytical-platform-data-engineering-sandbox-a

  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_roles" "data_engineering_team_access_role_data_production_data_eng" {
  provider = aws.analytical-platform-data-production

  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}
