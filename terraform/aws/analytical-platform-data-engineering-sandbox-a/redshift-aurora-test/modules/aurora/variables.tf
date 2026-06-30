variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the cluster will be deployed"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of database subnet IDs"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for security group rules"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Aurora cluster"
}

variable "engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version"
  default     = "16.1"
}

variable "instance_class" {
  type        = string
  description = "Instance class for Aurora instances"
  default     = "db.t3.medium"
}

variable "master_username" {
  type        = string
  description = "Master username for the database"
  default     = "postgres"
}

variable "database_name" {
  type        = string
  description = "Name of the default database"
  default     = "testdb"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for encryption"
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain backups"
  default     = 7
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = false # Set to false for test environment
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot when destroying"
  default     = true # Set to true for test environment
}

variable "redshift_security_group_id" {
  type        = string
  description = "Security group ID of Redshift for federated query access"
  default     = null
}
