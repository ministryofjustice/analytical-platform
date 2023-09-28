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

variable "noms_live_dead_end_cidr_block" {
  type        = string
  description = "CIDR range for NOMS live"
}

variable "laa_prod_cidr_block" {
  type        = string
  description = "CIDR range for LAA Prod"
}

variable "modernisation_platform_cidr_block" {
  type        = string
  description = "CIDR range for Modernisation Platform"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones in Ireland region"
}

variable "transit_gateway_ids" {
  type        = map(string)
  description = "Map of transit gateway names to ids"
}

##################################################
# EKS
##################################################

variable "node_group_instance_types" {
  type        = map(list(string))
  description = "Map of node group labels to instance types"
}

###################################################
############## Development Variables ##############
###################################################

variable "dev_vpc_cidr_block" {
  type        = string
  description = "CIDR range for the VPC"
}

variable "dev_eks_role_name" {
  type        = string
  description = "Name of cluster role for Airflow-Dev"
}

variable "dev_eks_cluster_name" {
  type        = string
  description = "Name of cluster for Airflow-Dev"
}

variable "dev_cluster_additional_sg_id" {
  type        = string
  description = "Name of cluster additional security group for Airflow-Dev"
}

variable "dev_cluster_additional_sg_name" {
  type        = string
  description = "Name of cluster additional security group for Airflow-Dev"
}

variable "dev_cluster_node_sg_id" {
  type        = string
  description = "ID of node security group for Airflow-Dev"
}

variable "dev_cluster_node_sg_name" {
  type        = string
  description = "ID of node security group for Airflow-Dev"
}

variable "dev_private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges"
}

variable "dev_public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDR ranges"
}

##################################################
############## Production Variables ##############
##################################################

variable "prod_vpc_cidr_block" {
  type        = string
  description = "CIDR range for the VPC"
}

variable "prod_eks_role_name" {
  type        = string
  description = "Name of role used by EKS cluster for Airflow-Prod"
}

variable "prod_eks_cluster_name" {
  type        = string
  description = "Name of cluster for Airflow-Prod"
}

variable "prod_cluster_additional_sg_id" {
  type        = string
  description = "Name of cluster additional security group for Airflow-Prod"
}

variable "prod_cluster_additional_sg_name" {
  type        = string
  description = "Name of cluster additional security group for Airflow-Prod"
}

variable "prod_node_sg_id" {
  type        = string
  description = "ID of node security group for Airflow-Prod"
}

variable "prod_private_subnet_cidrs" {
  type        = list(string)
  description = "List of private subnet CIDR ranges"
}

variable "prod_public_subnet_cidrs" {
  type        = list(string)
  description = "List of public subnet CIDR ranges"
}

variable "prod_vpc_sg_name" {
  type        = string
  description = "VPC security group"
}
