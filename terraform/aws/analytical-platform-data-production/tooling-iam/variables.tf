##################################################
# General
##################################################

variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "data_buckets" {
  type        = list(string)
  description = "List of data buckets containing Athena databases"
}

variable "athena_query_result_buckets" {
  type        = list(string)
  description = "Athena query dump buckets"
}

variable "datahub_cp_irsa_role_names" {
  type        = map(string)
  description = "Map of DataHub environments and their IRSA role names"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}
