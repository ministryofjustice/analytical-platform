data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "auth0_domain" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/alpha-analytics-moj/domain"
}

data "aws_secretsmanager_secret_version" "auth0_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/alpha-analytics-moj/client-id"
}

data "aws_secretsmanager_secret_version" "auth0_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/alpha-analytics-moj/client-secret"
}
