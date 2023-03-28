resource "pagerduty_service" "this" {
  name              = var.name
  escalation_policy = var.escalation_policy
}
