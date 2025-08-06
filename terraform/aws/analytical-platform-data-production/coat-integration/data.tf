data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "analytical_platform_platform_account_ids" {
  provider = aws.analytical-platform-management-production

  secret_id = "analytical-platform/platform-account-ids"
}
