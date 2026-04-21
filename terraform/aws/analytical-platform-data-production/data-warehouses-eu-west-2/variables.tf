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
  description = "Create a role that Home Office can assume to read data from nominated source buckets"
  default     = true

  validation {
    condition     = !var.home_office_copy_role_enabled || length(var.home_office_source_bucket_names) > 0
    error_message = "Set home_office_source_bucket_names to at least one bucket when home_office_copy_role_enabled is true."
  }

  validation {
    condition = !var.home_office_copy_role_enabled || (
      var.home_office_account_id != null || length(var.home_office_trusted_role_arns) > 0
    )
    error_message = "Set home_office_account_id or home_office_trusted_role_arns when home_office_copy_role_enabled is true."
  }
}

variable "home_office_account_id" {
  type        = string
  description = "Home Office AWS account ID used to build a default trust principal when explicit role ARNs are not provided"
  default     = "1234567890"
}

variable "home_office_trusted_role_arns" {
  type        = list(string)
  description = "Optional explicit Home Office role ARNs trusted to assume the AP copy role"
  default     = ["example-role-arn-placeholder"]
}

variable "home_office_source_bucket_names" {
  type        = list(string)
  description = "Names of source buckets the Home Office copy role can read"
  default     = ["bucket-name-placeholder"]
}

variable "home_office_copy_role_name" {
  type        = string
  description = "IAM role name for Home Office source bucket read access"
  default     = "home-office-source-s3-copy-read"
}
