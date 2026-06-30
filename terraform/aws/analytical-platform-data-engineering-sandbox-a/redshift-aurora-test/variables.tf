variable "account_ids" {
  type        = map(string)
  description = "Map of account names to account IDs"
}

variable "tags" {
  type        = map(string)
  description = "Map of tags to apply to resources"
  default     = {}
}

variable "project_name" {
  type        = string
  description = "Name of the project"
  default     = "redshift-aurora-test"
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "sandbox"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
  default     = "10.100.0.0/16"
}

variable "aurora_instance_class" {
  type        = string
  description = "Instance class for Aurora cluster"
  default     = "db.t3.medium"
}

variable "aurora_engine_version" {
  type        = string
  description = "Aurora PostgreSQL engine version"
  default     = "17.9"
}

variable "redshift_price_performance_level" {
  type        = number
  description = "Price-performance target level for Redshift Serverless (1=LOW_COST, 25=ECONOMICAL, 50=BALANCED, 75=RESOURCEFUL, 100=HIGH_PERFORMANCE)"
  default     = 1
}
