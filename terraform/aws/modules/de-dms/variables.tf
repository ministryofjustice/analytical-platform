variable "environment" {
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
    subnet_ids                 = list(string)
    allocated_storage          = number
    availability_zone          = string
    engine_version             = string
    kms_key_arn                = string
    multi_az                   = bool
    replication_instance_class = string
    vpc_security_group_ids     = list(string)
  })
}

variable "landing_bucket" {
  type = string
}

variable "landing_bucket_folder" {
  type = string
}
