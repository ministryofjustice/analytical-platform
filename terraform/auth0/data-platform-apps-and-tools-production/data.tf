  data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_secretsmanager_secret_version" "auth0_domain" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/domain"
}

data "aws_secretsmanager_secret_version" "auth0_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/client-id"
}

data "aws_secretsmanager_secret_version" "auth0_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "auth0/client-secret"
}

data "aws_cloudwatch_event_bus" "auth0" {
  name = "aws.partner/auth0.com/alpha-analytics-moj-5991c2c1-c1a9-40e6-8460-b4bef6f519e7/auth0.logs" // This was created by Auth0, we accepted it in the UI
}
