output "id" {
  value = pagerduty_service.this.id
}

output "type" {
  value = pagerduty_service.this.type
}

output "cloudwatch_integration_key" {
  value = var.enable_cloudwatch_integration ? pagerduty_service_integration.cloudwatch[0].integration_key : null
}

output "cloudtrail_integration_key" {
  value = var.enable_cloudtrail_integration ? pagerduty_service_integration.cloudtrail[0].integration_key : null
}

output "guardduty_integration_key" {
  value = var.enable_guardduty_integration ? pagerduty_service_integration.guardduty[0].integration_key : null
}

output "health_dashboard_integration_key" {
  value = var.enable_health_dashboard_integration ? pagerduty_service_integration.health_dashboard[0].integration_key : null
}

output "security_hub_integration_key" {
  value = var.enable_security_hub_integration ? pagerduty_service_integration.security_hub[0].integration_key : null
}

output "email_integration_key" {
  value = var.enable_email_integration ? pagerduty_service_integration.email[0].integration_email : null
}

output "airflow_integration_key" {
  value = var.enable_airflow_integration ? pagerduty_service_integration.airflow[0].integration_key : null
}

output "alert_manager_integration_key" {
  value = var.enable_alert_manager_integration ? pagerduty_service_integration.alert_manager[0].integration_key : null
}