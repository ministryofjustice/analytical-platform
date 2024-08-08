##################################################
# General
##################################################

variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "add_role_to_glue_policy" {
  description = "Add the source account role account to target account's Glue Catalogue resource policy (Requireed if Glue Catalogue has a resource policy defined"
  type        = bool
  default     = false
}