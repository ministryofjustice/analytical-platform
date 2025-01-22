variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db" {
  type = string
}

variable "source_secrets_manager_arn" {
  type = string
}

variable "dms_source_server_name" {
  type = string
}

variable "dms_source_server_port" {
  type    = string
  default = 1521 # Deafult Oracle DB port
}

variable "dms_source_database_name" {
  type = string
}

variable "dms_replication_instance" {
  type = object({
    replication_instance_id    = string
    subnet_group_id            = string
    allocated_storage          = number
    availability_zone          = string
    engine_version             = string
    kms_key_arn                = string
    multi_az                   = bool
    replication_instance_class = string
    inbound_cidr               = string
  })
}

variable "replication_task_id" {
  type = object({
    full_load = string
    cdc       = string
  })
}

variable "dms_mapping_rules" {
  type = string
}

variable "landing_bucket" {
  type = string
}

variable "landing_bucket_folder" {
  type = string
}

variable "s3_target_config" {
  type = object({
    add_column_name       = bool
    max_batch_interval    = number
    min_file_size         = number
    timestamp_column_name = string
  })
  default = {
    add_column_name       = true
    max_batch_interval    = 3600
    min_file_size         = 32000
    timestamp_column_name = "EXTRACTION_TIMESTAMP"
  }
}

variable "tags" {
  type = map(string)
}
