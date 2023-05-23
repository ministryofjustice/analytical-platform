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

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}
