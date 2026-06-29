data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

# Data block for Slack webhook for notifications
data "aws_secretsmanager_secret_version" "ae_download_athena_csv_secret_slack_webhook" {
  secret_id = module.ae_download_athena_csv_secret.secret_id
}

data "aws_iam_roles" "aws_sso_modernisation_platform_data_eng" {
  name_regex  = "AWSReservedSSO_modernisation-platform-data-eng_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "aws_sso_modernisation_platform_data_eng" {
  name = one(data.aws_iam_roles.aws_sso_modernisation_platform_data_eng.names)
}

data "aws_iam_roles" "aws_sso_mp_analytics_eng" {
  name_regex  = "AWSReservedSSO_mp-analytics-engineer.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "aws_sso_mp_analytics_eng" {
  name = one(data.aws_iam_roles.aws_sso_mp_analytics_eng.names)
}
