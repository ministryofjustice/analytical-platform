resource "pagerduty_escalation_policy" "this" {
  name        = var.name
  description = var.description
  num_loops   = var.num_loops
  teams       = [var.team]

  dynamic "rule" {
    for_each = var.rules
    content {
      escalation_delay_in_minutes = rule.value.escalation_delay_in_minutes
      dynamic "target" {
        for_each = rule.value.targets
        content {
          type = target.value.type
          id   = target.value.id
        }
      }
    }
  }
}
