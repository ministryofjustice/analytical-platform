variable "data_eng_role" {
  description = "IAM role ARN for the Data Engineering team"
  type        = string
}

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "eu-west-1"
}
variable "account_ids" {
  description = "Map of account IDs for each AWS account environment"
  type        = map(string)
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
}
variable "subnet_ids" {
  description = "List of subnet IDs for DMS replication subnet group."
  type        = list(string)
}

variable "source_database" {
  description = "Endpoint configuration for the source database."
  type = object({
    username      = string
    password      = string
    server_name   = string
    database_name = string
    port          = number
  })
}

variable "s3_bucket" {
  description = "S3 bucket name for DMS target endpoint."
  type        = string
}

variable "replication_instance_class" {
  description = "DMS instance class (e.g., dms.t3.micro)."
  type        = string
  default     = "dms.t3.micro"
}


variable "public_subnets" {
  description = "List of public subnets, including availability zones and CIDR blocks."
  type = list(object({
    availability_zone = string
    cidr_block        = string
  }))
}

variable "rds_params" {
  description = "List of RDS instance parameters, including engine type, version, and storage configuration."
  type = list(object({
    allocated_storage       = string
    engine                  = string
    engine_version          = string
    engine_family           = string
    instance_class          = string
    publicly_accessible     = bool
    dialect                 = string
    skip_final_snapshot     = bool
    backup_retention_period = number
  }))
}

variable "egress_rules" {
  description = "Egress security rules, specifying allowed outbound traffic."
  type = list(object({
    cidr_blocks      = list(string)
    description      = string
    from_port        = number
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    protocol         = string
    security_groups  = list(string)
    self             = bool
    to_port          = number
  }))
}

variable "ingress_rules" {
  description = "Ingress security rules, specifying allowed inbound traffic."
  type = list(object({
    cidr_blocks      = list(string)
    description      = string
    from_port        = number
    ipv6_cidr_blocks = list(string)
    prefix_list_ids  = list(string)
    protocol         = string
    security_groups  = list(string)
    self             = bool
    to_port          = number
  }))
}

variable "buckets" {
  description = "List of S3 buckets used for DMS data storage and replication."
  type        = list(string)
}
