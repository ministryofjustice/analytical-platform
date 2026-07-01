variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment"
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources, where applicable"
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "database_subnets" {
  description = "List of database subnets"
  type        = list(string)
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC's main CIDR block"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the AWS KMS key to be used to encrypt Redshift data"
}

variable "price_performance_level" {
  type        = number
  description = "Price-performance target level (1=LOW_COST, 25=ECONOMICAL, 50=BALANCED, 75=RESOURCEFUL, 100=HIGH_PERFORMANCE)"
  default     = 50
}
