variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "alpha_mojap_ho_data_transfer_replication_enabled" {
  type        = bool
  description = "Enable cross-account replication from alpha-mojap-ho-data-transfer-test"
  default     = true
}
