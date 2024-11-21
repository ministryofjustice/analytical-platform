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
