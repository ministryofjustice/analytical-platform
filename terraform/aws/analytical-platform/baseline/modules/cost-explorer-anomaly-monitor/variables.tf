variable "pagerduty_service" {
  type        = string
  description = "The PagerDuty service to send the alert"
}

variable "ce_anomaly_subscription_threshold_expression_dimension" {
  type        = string
  description = "The type of expression to use for the anomaly subscription, either ANOMALY_TOTAL_IMPACT_ABSOLUTE or ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  default     = "ANOMALY_TOTAL_IMPACT_PERCENTAGE"
}

variable "ce_anomaly_subscription_threshold_expression_value" {
  type        = string
  description = "The value of expression to use for the anomaly subscription, dollars for ANOMALY_TOTAL_IMPACT_ABSOLUTE or percentage for ANOMALY_TOTAL_IMPACT_PERCENTAGE"
  default     = "15"
}
