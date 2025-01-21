variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "replication_subnet_group_id" {
  type = string
}

variable "import_ids" {
  type = object({
    vpc                                     = string
    default_security_group                  = string
    private_network_acl                     = string
    default_route_table                     = string
    vpc_endpoint_security_group             = map(string)
    dms_replication_instance_security_group = map(string)
    vpc_endpoint                            = map(string)
    route_table_private                     = map(string)
    private_subnets                         = map(map(string))
  })
}

variable "dms_config" {
  sensitive = true
  type = map(object({
    source_secrets_manager_arn = string
    role_name                  = string
    #source_server_name          = string
    #source_server_port          = number
    #source_database_name        = string
    replication_instance = object({
      replication_instance_id   = string
      security_group_id         = string
      security_group_ingress_id = string
      security_group_egress_id  = string
      #  allocated_storage          = number
      #  availability_zone          = string
      #  engine_version             = string
      #  kms_key_arn                = string
      #  multi_az                   = bool
      #  replication_instance_class = string
      #  inbound_cidr               = string
    })
    #replication_task_id = object({
    #  full_load = string
    #  cdc       = string
    #})
    #mapping_rules = string
    landing_bucket        = string
    landing_bucket_folder = string
    metadata_bucket       = string
    fail_bucket           = string
    raw_hist_bucket       = string
    slack_secret_arn      = string
    full_load_task_id     = string
    cdc_task_id           = string
  }))
}
