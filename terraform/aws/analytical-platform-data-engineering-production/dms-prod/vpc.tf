locals {
  name = "eu-west-1-prod"

  tgw_destinations = [
    "10.26.12.211/32",
    "10.27.0.0/16",
    "10.40.0.0/18",
    "10.40.64.0/18",
    "10.160.16.0/20",
    "172.20.0.0/16"
  ]

  route_tables_ids = toset(module.vpc.private_route_table_ids)

  route_dest_pairs = flatten([
    for rt in local.route_tables_ids : [
      for dest in local.tgw_destinations : {
        route_table_id = rt
        destination    = dest
        pair_key       = "${rt}-${replace(dest, "/", "-")}"
      }
    ]
  ])
}

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=7c1f791efd61f326ed6102d564d1a65d1eceedf0"
  name   = local.name
  cidr   = "172.25.0.0/16"
  azs    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  private_subnets      = ["172.25.0.0/20", "172.25.16.0/20", "172.25.32.0/20"]
  private_subnet_names = ["private-eu-west-1a-prod", "private-eu-west-1b-prod", "private-eu-west-1c-prod"]

  enable_nat_gateway = false

  tags = var.tags
  private_subnet_tags = {
    network = "Private"
  }
  private_route_table_tags = {
    network = "Private"
  }
}

module "endpoints" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "Managed by Pulumi"
  security_group_tags        = { Name : "eu-west-1-prod" }

  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    # interface endpoints  need  subnet_ids and sg_id.

    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "ec2messages-eu-west-1-prod" }
    }

    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "ssmmessages-eu-west-1-prod" }
    }

    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "ssm-eu-west-1-prod" }
    }

    s3 = {
      service_type    = "Gateway"
      service         = "s3"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = { Name = "s3-eu-west-1-prod" }
    }

    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "secretsmanager-eu-west-1-prod" }
    }

    glue = {
      service             = "glue"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }

    sts = {
      service             = "sts"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
      tags                = { Name = "sts-eu-west-1-prod" }
    }
  }

  tags = merge(var.tags, { network = "Private" })
}

resource "aws_route" "routes" {
  for_each               = { for pair in local.route_dest_pairs : pair.pair_key => pair }
  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination
  transit_gateway_id     = "tgw-0e7b982ea47c28fba"
}
