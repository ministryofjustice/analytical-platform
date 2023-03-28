resource "pagerduty_escalation_policy" "this" {
  name      = var.name
  num_loops = var.num_loops
  teams     = [var.team]

  rule {
    escalation_delay_in_minutes = var.escalation_delay_in_minutes
    dynamic "target" {
      for_each = var.targets
      content {
        type = target.value.type
        id   = target.value.id
      }
    }
  }
}
