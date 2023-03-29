resource "pagerduty_service" "this" {
  name              = var.name
  description       = var.description
  escalation_policy = var.escalation_policy
  alert_creation    = var.alert_creation
}
