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
variable "dms_task_arn" {
  description = "ARN of the DMS replication task (dev)"
  type        = string
}
