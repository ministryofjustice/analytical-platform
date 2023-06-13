locals {
  pagerduty_alerting_endpoint = "https://events.pagerduty.com/integration/${data.aws_secretsmanager_secret_version.pagerduty_analytical_platform_security_guardduty_integration_key.secret_string}/enqueue"
}
