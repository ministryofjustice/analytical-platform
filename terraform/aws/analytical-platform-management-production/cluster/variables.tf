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
# Route53
##################################################

variable "route53_zone" {
  type        = string
  description = "Name of the Route53 zone"
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

##################################################
# EKS
##################################################

variable "eks_versions" {
  type        = map(string)
  description = "The versions of EKS to provision"
}

variable "eks_addon_versions" {
  type        = map(string)
  description = "The versions of EKS addons to provision"
}

variable "eks_role_mappings" {
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  description = "IAM roles to add to the aws-auth configmap"
}

variable "eks_node_group_ami_type" {
  type        = string
  description = "The type of AMI to use for the EKS node group"
}

variable "eks_node_group_instance_types" {
  type        = list(string)
  description = "The instance types for the EKS node group"
}

variable "eks_node_group_disk_size" {
  type        = number
  description = "The disk size for the EKS node group"
}

variable "eks_node_group_name_prefix" {
  type        = string
  description = "Prefix for the EKS node group"
}

variable "eks_node_group_capacities" {
  type        = map(number)
  description = "The desired capacities for the EKS node group"
}

##################################################
# AWS SSO
##################################################

variable "aws_sso_role_prefix" {
  type        = string
  description = "The prefix of the SSO role to use when assigning administrator permissions in the cluster"
  default     = "AdministratorAccess"
}
