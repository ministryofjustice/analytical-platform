resource "pagerduty_service" "this" {
  name                    = var.name
  description             = var.description
  escalation_policy       = var.escalation_policy
  alert_creation          = var.alert_creation
  auto_resolve_timeout    = var.auto_resolve_timeout
  acknowledgement_timeout = var.acknowledgement_timeout

  dynamic "auto_pause_notifications_parameters" {
    for_each = var.auto_pause_notifications_parameters

    content {
      enabled = auto_pause_notifications_parameters.value.enabled
      timeout = auto_pause_notifications_parameters.value.timeout
    }
  }

  dynamic "support_hours" {
    for_each = var.support_hours
    content {
      type         = support_hours.value["type"]
      start_time   = support_hours.value["start_time"]
      end_time     = support_hours.value["end_time"]
      time_zone    = support_hours.value["time_zone"]
      days_of_week = support_hours.value["days_of_week"]
    }
  }

  dynamic "incident_urgency_rule" {
    for_each = { for incident_urgency_rule in var.incident_urgency_rules : incident_urgency_rule.type => incident_urgency_rule }

    content {
      type    = incident_urgency_rule.value.type
      urgency = incident_urgency_rule.value.urgency

      dynamic "during_support_hours" {
        for_each = incident_urgency_rule.value.during_support_hours

        content {
          type    = during_support_hours.value.type
          urgency = during_support_hours.value.urgency
        }
      }

      dynamic "outside_support_hours" {
        for_each = incident_urgency_rule.value.outside_support_hours

        content {
          type    = outside_support_hours.value.type
          urgency = outside_support_hours.value.urgency
        }
      }
    }
  }
}

resource "pagerduty_service_integration" "cloudwatch" {
  count = var.enable_cloudwatch_integration ? 1 : 0

  name    = data.pagerduty_vendor.cloudwatch.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.cloudwatch.id
}

resource "pagerduty_service_integration" "github" {
  count = var.enable_github_integration ? 1 : 0

  name    = data.pagerduty_vendor.github.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.github.id
}
