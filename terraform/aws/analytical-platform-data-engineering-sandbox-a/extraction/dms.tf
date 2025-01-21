# This is created outside of the module as it is reused for each environment.
resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  replication_subnet_group_description = "Subnet group for DMS replication instances"
  replication_subnet_group_id          = "${data.aws_region.current.name}-${var.environment}"

  subnet_ids = [for private_subnet in aws_subnet.private : private_subnet.id]

  tags = merge(local.tags,
    {
      Name        = "${data.aws_region.current.name}-${var.environment}"
      application = "Data Engineering"
    }
  )
}

module "dms" {
  source = "../../modules/de-dms"

  for_each = nonsensitive(toset(keys(var.dms_config)))

  environment                = var.environment
  vpc_id                     = module.vpc.vpc_id
  db                         = "oracle19"
  source_secrets_manager_arn = "managed_pipelines/sandbox/oracle19"
  dms_source_server_name     = "oracle19.cn2clhldf81y.eu-west-1.rds.amazonaws.com"
  dms_source_database_name   = "oracle19"
  landing_bucket             = "mojap-land-sandbox"
  landing_bucket_folder      = "hmpps/oracle19"
  replication_task_id = {
    full_load = "oracle19-1-1-full-load-eu-west-1-sandbox"
    cdc       = "oracle19-1-0-cdc-eu-west-1-sandbox"
  }


  dms_replication_instance = {
    replication_instance_id    = var.dms_config[each.key].replication_instance.replication_instance_id
    allocated_storage          = 50
    availability_zone          = "eu-west-1a"
    engine_version             = "3.5.3"
    kms_key_arn                = var.dms_config[each.key].source_secrets_manager_arn
    multi_az                   = false
    replication_instance_class = "dms.t2.micro"
    subnet_group_id            = aws_dms_replication_subnet_group.replication_subnet_group.id
    inbound_cidr               = var.import_ids.private_subnets["eu-west-1a"].cidr
  }

  dms_mapping_rules = file("${path.module}/sandbox_mappings.json")

  tags = {
    business-unit    = "Platforms"
    application      = "oracle19"
    environment-name = "sandbox"
    is-production    = "False"
    owner            = "Data Engineering:dataengineering@digital.justice.gov.uk"
  }
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_dms_endpoint.source
  id       = "${each.key}-source-${data.aws_region.current.name}-${var.environment}"
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_iam_role.dms
  id       = var.dms_config[each.key].role_name
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_iam_role_policy.dms
  id       = "${each.key}-dms-${var.environment}:${each.key}-dms-${var.environment}"
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_dms_s3_endpoint.s3_target
  id       = "${each.key}-target-${data.aws_region.current.name}-${var.environment}"
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_security_group.replication_instance
  id       = var.dms_config[each.key].replication_instance.security_group_id
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_dms_replication_instance.instance
  id       = var.dms_config[each.key].replication_instance.replication_instance_id
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_vpc_security_group_ingress_rule.replication_instance_inbound
  id       = var.dms_config[each.key].replication_instance.security_group_ingress_id
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_vpc_security_group_egress_rule.replication_instance_outbound
  id       = var.dms_config[each.key].replication_instance.security_group_egress_id
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_dms_replication_task.full_load_replication_task
  id       = var.dms_config[each.key].full_load_task_id
}

import {
  for_each = nonsensitive(toset(keys(var.dms_config)))
  to       = module.dms[each.key].aws_dms_replication_task.cdc_replication_task
  id       = var.dms_config[each.key].cdc_task_id
}
