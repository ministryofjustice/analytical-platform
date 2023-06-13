data "aws_caller_identity" "target" {
  provider = aws.target
}

data "aws_secretsmanager_secret_version" "pagerduty_cloudwatch_integration_key" {
  provider = aws.management

  secret_id = "pagerduty/${var.pagerduty_service}/integration-keys/cloudwatch"
}
