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

variable "restricted_principal_arn" {
  description = "The IAM role that should receive restricted Athena/Lake Formation access"
  type        = string
}

variable "restricted_tables" {
  description = "Tables with allowed columns and optional row filters"

  type = map(object({
    database_name   = string
    table_name      = string
    allowed_columns = set(string)
    row_filter      = string
  }))
}
