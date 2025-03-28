data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret" "pagerduty_token" {
  name = "pagerduty-token"
}

data "aws_secretsmanager_secret_version" "pagerduty_token" {
  secret_id = data.aws_secretsmanager_secret.pagerduty_token.id
}
