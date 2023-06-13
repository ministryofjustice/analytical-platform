variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}

variable "pagerduty_services" {
  type        = map(map(string))
  description = "Map of account names to PagerDuty services"
}
