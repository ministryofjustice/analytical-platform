##################################################
# General
##################################################

variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
}

##################################################
# PagerDuty
##################################################

variable "pagerduty_services" {
  type        = map(map(string))
  description = "Map of account names to PagerDuty services"
}

##################################################
# Observability Platform
##################################################

variable "observability_platform_account_ids" {
  type        = map(string)
  description = "Map of Observability Platform account names to account IDs"
}
