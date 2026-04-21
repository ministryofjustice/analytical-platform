variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "home_office_copy_role_enabled" {
  type        = bool
  description = "Create a role that Home Office can assume to read data from source buckets"
  default     = true
}

variable "home_office_source_bucket_names" {
  type        = list(string)
  description = "Names of source buckets the Home Office copy role can read"
  default     = ["bucket-name-placeholder"]
}
