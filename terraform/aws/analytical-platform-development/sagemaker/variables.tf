variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "auth_mode" {
  description = "The mode of authentication that members use to access the domain. Valid values are IAM and SSO"
  type        = string
  default     = "SSO"
}

variable "domain_name" {
  description = "Sagemaker Domain Name"
  type        = string
  default     = "mvp-studio-domain"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}
