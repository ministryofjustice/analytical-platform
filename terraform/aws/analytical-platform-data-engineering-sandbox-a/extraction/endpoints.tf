resource "aws_security_group" "vpc_endpoint" {
  name        = var.import_ids.vpc_endpoint_security_group.name
  description = "Managed by Pulumi"
  vpc_id      = module.vpc.vpc_id

  tags = merge({
    "Name" : "${data.aws_region.current.name}-${var.environment}",
  }, local.tags)
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_inbound" {
  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}


resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_outbound" {
  security_group_id = aws_security_group.vpc_endpoint.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

data "aws_iam_policy_document" "s3_gateway" {
  version = "2008-10-17"
  statement {
    effect    = "Allow"
    actions   = ["*"]
    resources = ["*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"

  vpc_id             = module.vpc.vpc_id
  security_group_ids = [aws_security_group.vpc_endpoint.id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = [for route_table in aws_route_table.private : route_table.id]
      policy          = data.aws_iam_policy_document.s3_gateway.json
      tags = merge({
        "Name" : "s3-${data.aws_region.current.name}-${var.environment}",
        "network" : "Private"
      }, local.tags)
    }

    ec2messages = {
      service      = "ec2messages"
      service_type = "Interface"
      subnet_ids   = [var.import_ids.private_subnets["eu-west-1a"].subnet]
      tags = merge({
        "Name" : "ec2messages-eu-west-1a-${var.environment}",
        "network" : "Private"
      }, local.tags)
    }

    ssm = {
      service      = "ssm"
      service_type = "Interface"
      subnet_ids   = [var.import_ids.private_subnets["eu-west-1a"].subnet]
      tags = merge({
        "Name" : "ssm-eu-west-1a-${var.environment}",
        "network" : "Private"
      }, local.tags)
    }

    ssmmessages = {
      service      = "ssmmessages"
      service_type = "Interface"
      subnet_ids   = [var.import_ids.private_subnets["eu-west-1a"].subnet]
      tags = merge({
        "Name" : "ssmmessages-eu-west-1a-${var.environment}",
        "network" : "Private"
      }, local.tags)
    }
  }
}

import {
  to = aws_security_group.vpc_endpoint
  id = var.import_ids.vpc_endpoint_security_group.id
}

import {
  to = aws_vpc_security_group_ingress_rule.vpc_endpoint_inbound
  id = var.import_ids.vpc_endpoint_security_group.ingress_rule_id
}

import {
  to = aws_vpc_security_group_egress_rule.vpc_endpoint_outbound
  id = var.import_ids.vpc_endpoint_security_group.egress_rule_id
}

import {
  to = module.endpoints.aws_vpc_endpoint.this["s3"]
  id = var.import_ids.vpc_endpoint.s3
}

import {
  to = module.endpoints.aws_vpc_endpoint.this["ec2messages"]
  id = var.import_ids.vpc_endpoint.ec2messages
}

import {
  to = module.endpoints.aws_vpc_endpoint.this["ssm"]
  id = var.import_ids.vpc_endpoint.ssm
}

import {
  to = module.endpoints.aws_vpc_endpoint.this["ssmmessages"]
  id = var.import_ids.vpc_endpoint.ssmmessages
}
