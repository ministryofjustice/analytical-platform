variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db" {
  type = string
}

variable "dms_replication_instance" {
  type = object({
    replication_instance_id    = string
    subnet_group_id            = optional(string)
    subnet_group_name          = optional(string)
    subnet_ids                 = optional(list(string))
    allocated_storage          = number
    availability_zone          = string
    engine_version             = string
    kms_key_arn                = optional(string)
    multi_az                   = bool
    replication_instance_class = string
    inbound_cidr               = string
  })

  validation {
    condition     = contains(["3.5.2", "3.5.3", "3.5.4"], var.dms_replication_instance.engine_version)
    error_message = "Valid values for var: test_variable are ('3.5.2', '3.5.3', '3.5.4')."
  }
}

variable "replication_task_id" {
  type = object({
    full_load = string
    cdc       = string
  })
}

variable "dms_source" {
  type = object({
    engine_name                 = string,
    secrets_manager_arn         = string,
    sid                         = string,
    extra_connection_attributes = optional(string)
    cdc_start_time              = optional(string)
  })

  validation {
    condition     = contains(["oracle"], var.dms_source.engine_name)
    error_message = "Valid values for var: test_variable are ('oracle')."
  }
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
