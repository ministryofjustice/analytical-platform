data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

# # Data block for Slack webhook for notifications
# data "aws_secretsmanager_secret_version" "ae_download_athena_csv_secret_slack_webhook" {
#   secret_id = module.ae_download_athena_csv_secret.secret_id
# }
