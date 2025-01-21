locals {
  tags = {
    business-unit    = "Platforms"
    application      = "Data Engineering"
    environment-name = "sandbox"
    is-production    = "False"
    owner            = "Data Engineering:dataengineering@digital.justice.gov.uk"
  }
}

module "vpc" {
  source = "git::http://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=9ffd9c66f3d7eb4b5bc2d7bc7d049f794b127693"

  name = "${data.aws_region.current.name}-${var.environment}"

  cidr = var.vpc_cidr

  # Recources not to manage by the registry module
  # This is to match the existing resources in the account (Mostly due to tagging)
  manage_default_security_group = false
  manage_default_network_acl    = false
  manage_default_route_table    = false

  enable_nat_gateway = false

  vpc_tags                = local.tags
  igw_tags                = merge(local.tags, { Name = "igw-${var.environment}" })
  public_route_table_tags = merge(local.tags, { Name = "public-${var.environment}" })
}

resource "aws_default_security_group" "default" {
  vpc_id = module.vpc.vpc_id
}

resource "aws_network_acl" "private" {
  vpc_id     = module.vpc.vpc_id
  subnet_ids = [for private_subnet in aws_subnet.private : private_subnet.id]

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge({
    "Name" : "${data.aws_region.current.name}-${var.environment}",
    "network" : "Private",
    },
    local.tags
  )
}

resource "aws_default_route_table" "default" {
  default_route_table_id = var.import_ids.default_route_table
}

resource "aws_subnet" "private" {
  for_each = var.import_ids.private_subnets

  vpc_id     = module.vpc.vpc_id
  cidr_block = each.value.cidr

  availability_zone = each.key
  tags = merge({
    "Name" : "private-${each.key}-${var.environment}",
    "network" : "Private"
  }, local.tags)
}

resource "aws_route_table" "private" {
  for_each = var.import_ids.route_table_private
  vpc_id   = var.import_ids.vpc

  tags = merge(
    {
      "Name"    = "private-${each.key}-${var.environment}",
      "network" = "Private"
    },
    local.tags,
  )
}

resource "aws_route" "private_vpc_traffic" {
  for_each               = aws_route_table.private
  route_table_id         = each.value.id
  gateway_id             = "local"
  destination_cidr_block = module.vpc.vpc_cidr_block
}

import {
  to = aws_dms_replication_subnet_group.replication_subnet_group
  id = var.replication_subnet_group_id
}

import {
  to = module.vpc.aws_vpc.this[0]
  id = var.import_ids.vpc
}

import {
  to = aws_default_security_group.default
  id = var.import_ids.default_security_group
}

import {
  to = aws_network_acl.private
  id = var.import_ids.private_network_acl
}

import {
  to = aws_default_route_table.default
  id = var.import_ids.vpc
}

import {
  for_each = var.import_ids.route_table_private
  to       = aws_route_table.private[each.key]
  id       = var.import_ids.route_table_private[each.key]
}

import {
  for_each = var.import_ids.private_subnets
  to       = aws_subnet.private[each.key]
  id       = each.value.subnet
}

import {
  for_each = var.import_ids.route_table_private
  to       = aws_route.private_vpc_traffic[each.key]
  id       = "${each.value}_${module.vpc.vpc_cidr_block}"
}
