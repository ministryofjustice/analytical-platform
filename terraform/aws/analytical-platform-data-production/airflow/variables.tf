##################################################
# General
##################################################

variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "target_account" {
  type        = string
  description = "Name of the account to deploy to"
}

variable "assume_role" {
  type        = string
  description = "Name of the role to assume in each account"
  default     = "GlobalGitHubActionAdmin"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}
