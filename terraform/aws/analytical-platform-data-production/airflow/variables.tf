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

##################################################
# Network
##################################################

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR range for the VPC"
}

variable "noms_live_dead_end" {
  type        = string
  description = "CIDR range for NOMS live"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones in Ireland region"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDR ranges"
}

variable "transit_gateway_ids" {
  type        = map(string)
  description = "Map of transit gateway names to ids"
}

