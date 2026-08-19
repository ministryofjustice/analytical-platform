variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "splink_alert_email" {
  type        = string
  description = "Email address for S3 and security alerts (requires manual confirmation)"
  sensitive   = false
}
