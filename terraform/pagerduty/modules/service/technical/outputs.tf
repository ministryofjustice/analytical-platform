output "id" {
  value = pagerduty_service.this.id
}

output "type" {
  value = pagerduty_service.this.type
}

output "cloudwatchwatch_integration_key" {
  value = var.enable_cloudwatch_integration ? pagerduty_service_integration.cloudwatch[0].integration_key : null
}

output "github_integration_key" {
  value = var.enable_cloudwatch_integration ? pagerduty_service_integration.github[0].integration_key : null
}
