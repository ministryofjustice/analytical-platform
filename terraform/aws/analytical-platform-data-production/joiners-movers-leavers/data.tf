data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "govuk_notify_api_key" {
  secret_id = aws_secretsmanager_secret.govuk_notify_api_key.id
}

data "aws_secretsmanager_secret_version" "jml_email" {
  secret_id = aws_secretsmanager_secret.jml_email.id
}

data "aws_cloudwatch_log_group" "jml_cloudwatch_log_group" {
  name = aws_cloudwatch_event_rule.jml_lambda_trigger.name
}
