variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
  default     = "sandbox"
}

##################################################
# VPC
##################################################

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_private_subnets" {
  type        = list(string)
  description = "List of private subnets"
}

variable "vpc_public_subnets" {
  type        = list(string)
  description = "List of public subnets"
}

variable "vpc_database_subnets" {
  type        = list(string)
  description = "List of database subnets"
}
