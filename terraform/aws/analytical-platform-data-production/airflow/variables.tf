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

variable "noms_live_dead_end_cidr_block" {
  type        = string
  description = "CIDR range for NOMS live"
}

variable "modernisation_platform_cidr_block" {
  type        = string
  description = "CIDR range for Modernisation Platform"
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

variable "dev_eks_role_arn" {
  type        = string
  description = "ARN of role used by EKS cluster for Airflow-Dev"
}

variable "dev_cluster_sg_name" {
  type        = string
  description = "Name of cluster security group for Airflow-Dev"
}

variable "dev_node_sg_id" {
  type        = string
  description = "ID of node security group for Airflow-Dev"
}

variable "prod_cluster_sg_name" {
  type        = string
  description = "Name of cluster security group for Airflow-Prod"
}

variable "prod_node_sg_id" {
  type        = string
  description = "ID of node security group for Airflow-Prod"
}