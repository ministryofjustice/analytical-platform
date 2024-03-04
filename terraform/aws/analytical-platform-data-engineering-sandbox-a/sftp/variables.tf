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
}

variable "supplier" {
  type        = string
  description = "Name of the supplier"
}

variable "user_name" {
  description = "The user name for the SFTP server account"
  type        = string
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

variable "nat_gateway_bandwidth_alarm_threshold" {
  type        = number
  description = "Threshold value of how much bandwidth should trigger alert"
}
