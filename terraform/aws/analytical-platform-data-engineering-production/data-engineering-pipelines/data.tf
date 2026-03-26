data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

# Data block for Slack webhook for notifications
data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = "slack_webhook_ppud_dev"
}