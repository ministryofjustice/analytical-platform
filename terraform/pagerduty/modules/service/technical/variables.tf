variable "name" {
  type        = string
  description = "Name of the technical service"
}

variable "description" {
  type        = string
  description = "Description of the technical service"
}

variable "escalation_policy" {
  type        = string
  description = "ID of the escalation policy to use"
}

variable "alert_creation" {
  type        = string
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service#alert_creation"
}

variable "auto_resolve_timeout" {
  type        = number
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service#auto_resolve_timeout"
}

variable "acknowledgement_timeout" {
  type        = number
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service#acknowledgement_timeout"
}

variable "auto_pause_notifications_parameters" {
  type = list(object({
    enabled = bool
    timeout = number
  }))
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service"
}

variable "support_hours" {
  type = list(object({
    type         = string
    start_time   = string
    end_time     = string
    time_zone    = string
    days_of_week = list(number)
  }))
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service"
}

variable "incident_urgency_rules" {
  type = list(object({
    type                  = string
    urgency               = optional(string)
    during_support_hours  = list(object({ type = string, urgency = string }))
    outside_support_hours = list(object({ type = string, urgency = string }))
  }))
  description = "see https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/service"
}

variable "enable_cloudwatch_integration" {
  type        = bool
  description = "Enable CloudWatch integration for this service"
}

variable "enable_github_integration" {
  type        = bool
  description = "Enable Github integration for this service"
}
