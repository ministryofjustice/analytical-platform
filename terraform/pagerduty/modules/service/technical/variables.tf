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
  default     = "create_alerts_and_incidents"
}
