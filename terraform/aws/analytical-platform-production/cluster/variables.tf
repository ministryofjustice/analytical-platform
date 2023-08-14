##################################################
# General
##################################################

variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "environment" {
  type        = string
  description = "Name of the environment"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix to use for resources"
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

variable "vpc_database_subnets" {
  type        = list(string)
  description = "List of database subnets"
}

variable "nat_gateway_bandwidth_alarm_threshold" {
  type        = number
  description = "Threshold value of how much bandwidth should trigger alert"
}

##################################################
# EFS
##################################################

variable "efs_file_system_performance_mode" {
  type        = string
  description = "Performance mode for the EFS file system"
}

variable "efs_file_system_throughput_mode" {
  type        = string
  description = "Throughput mode for the EFS file system"
}

variable "efs_low_credit_burst_balance_alarm_threshold" {
  type        = number
  description = "The minimum number of burst credits that a file system should have"
}

##################################################
# RDS
##################################################

variable "rds_instance_class" {
  type        = string
  description = "Instance class for the RDS instance"
}

variable "rds_engine_version" {
  type        = string
  description = "Version of the RDS engine"
}

variable "rds_engine" {
  type        = string
  description = "Engine for the RDS instance"
}

variable "rds_family" {
  type        = string
  description = "Family of the RDS engine"
}

variable "rds_allocated_storage" {
  type        = number
  description = "Allocated storage for the RDS instance"
}

variable "rds_db_name" {
  type        = string
  description = "Name of the RDS database"
}

variable "rds_port" {
  type        = number
  description = "Port for the RDS instance"
  default     = 5432
}

variable "rds_snapshot_identifier" {
  type        = string
  description = "Snapshot identifier for the RDS instance"
}

variable "rds_maintenance_window" {
  type        = string
  description = "Maintenance window for the RDS instance"
}

variable "rds_backup_window" {
  type        = string
  description = "Backup window for the RDS instance"
}

variable "rds_monitoring_interval" {
  type        = number
  description = "Monitoring interval for the RDS instance"
}

variable "rds_monitoring_role_name" {
  type        = string
  description = "Name of the monitoring role for the RDS instance"
}

variable "rds_paramaters" {
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string)
  }))
  description = "List of parameters for the RDS instance"
}

variable "rds_timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  description = "Timeouts for the RDS instance"
}

variable "rds_deletion_protection" {
  type        = bool
  description = "Whether or not deletion protection should be enabled for the RDS instance"
}

variable "rds_multi_az" {
  type        = bool
  description = "Whether or not multi-AZ should be enabled for the RDS instance"
}

variable "rds_storage_encrypted" {
  type        = bool
  description = "Whether or not storage encryption should be enabled for the RDS instance"
}

variable "rds_high_cpu_utilisation_alarm_threshold" {
  type        = number
  description = "Threshold value of how much CPU utilisation should trigger alert"
}

variable "rds_low_cpu_credit_balance_alarm_threshold" {
  type        = number
  description = "Threshold value of how much CPU credit balance should trigger alert"
}

variable "rds_high_disk_queue_depth_alarm_threshold" {
  type        = number
  description = "Threshold value of how much disk queue depth should trigger alert"
}

variable "rds_low_free_storage_space_alarm_threshold" {
  type        = number
  description = "Threshold value of how much disk space should trigger alert"
}

variable "rds_low_disk_burst_balance_alarm_threshold" {
  type        = number
  description = "Threshold value of how much burst balance should trigger alert"
}

variable "rds_low_freeable_memory_alarm_threshold" {
  type        = number
  description = "Threshold value of how much freeable memory should trigger alert"
}

variable "rds_high_swap_usage_alarm_threshold" {
  type        = number
  description = "Threshold value of how much swap usage should trigger alert"
}

##################################################
# Redis
##################################################

variable "redis_instance_type" {
  type        = string
  description = "Instance type for the Redis cluster"
}

variable "redis_family" {
  type        = string
  description = "Family of the Redis engine"
}

variable "redis_engine_version" {
  type        = string
  description = "Version of the Redis engine"
}

variable "redis_cluster_size" {
  type        = number
  description = "Number of nodes in the Redis cluster"
}

variable "redis_namespace" {
  type        = string
  description = "Namespace for the Redis cluster"
}

variable "redis_enabled" {
  type        = bool
  description = "Whether or not the Redis cluster should be enabled"
}

variable "redis_at_rest_encryption_enabled" {
  type        = bool
  description = "Whether or not encryption at rest should be enabled for the Redis cluster"
}

variable "redis_automatic_failover_enabled" {
  type        = bool
  description = "Whether or not automatic failover should be enabled for the Redis cluster"
}

variable "redis_multi_az_enabled" {
  type        = bool
  description = "Whether or not multi-AZ should be enabled for the Redis cluster"
}

variable "redis_transit_encryption_enabled" {
  type        = bool
  description = "Whether or not transit encryption should be enabled for the Redis cluster"
}

variable "redis_alarm_cpu_threshold_percent" {
  type        = number
  description = "The redis CPU threshold to alarm on"
}

variable "redis_alarm_memory_threshold_bytes" {
  type        = number
  description = "The redis memory threshold to alarm on"
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

##################################################
# Control Panel
##################################################

variable "control_panel_kubernetes_service_account" {
  type        = string
  description = "The kubernetes service account that the control panel runs as e.g. cpanel:cpanel-frontend"
}

variable "control_panel_celery_kubernetes_service_account" {
  type        = string
  description = "The kubernetes service account that the control panel runs as e.g. cpanel:cpanel-celery-worker"
}
