data "aws_caller_identity" "target" {
  provider = aws.target
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_security_guardduty_integration_key" {
  provider = aws.management

  secret_id = "pagerduty/analytical-platform-security/integration-keys/guardduty"
}
