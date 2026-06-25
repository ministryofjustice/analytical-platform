terraform {
  required_version = "~> 1.5"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  # checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${var.project_name}-${var.environment}"
  cidr = var.vpc_cidr

  azs              = local.azs
  private_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  database_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 2)]
  public_subnets   = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 4)]

  create_database_subnet_group = true
  database_subnet_group_name   = "${var.project_name}-${var.environment}-db"

  enable_nat_gateway = true
  single_nat_gateway = true # Cost savings for test environment

  enable_dns_hostnames = true
  enable_dns_support   = true

  # VPC Flow Logs
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = var.tags
}

# VPC Endpoints for AWS services (reduces NAT Gateway costs and improves security)
module "vpc_endpoints" {
  # checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "${var.project_name}-s3-endpoint" }
    }
    secretsmanager = {
      service             = "secretsmanager"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.project_name}-secretsmanager-endpoint" }
    }
    sts = {
      service             = "sts"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpc_endpoints.id]
      tags                = { Name = "${var.project_name}-sts-endpoint" }
    }
  }

  tags = var.tags
}

resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-vpc-endpoints-"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-vpc-endpoints"
  })

  lifecycle {
    create_before_destroy = true
  }
}
