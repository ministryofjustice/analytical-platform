variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "namespace" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "eu-west-2"
}

variable "evaluation_interval" {
  type        = string
  description = "Default evaluation interval for rules (e.g. '1m', '5m')"
  default     = "1m"
}
