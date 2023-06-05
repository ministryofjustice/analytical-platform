data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_secretsmanager_secret" "pagerduty_token" {
  name = "pagerduty-token"
}

data "aws_secretsmanager_secret_version" "pagerduty_token" {
  secret_id = data.aws_secretsmanager_secret.pagerduty_token.id
}

data "pagerduty_business_service" "cloud_platform" {
  name = "Cloud Platform"
}

data "pagerduty_business_service" "modernisation_platform" {
  name = "Modernisation Platform"
}
