module "vpc_dev" {

  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc?ref=7c1f791efd61f326ed6102d564d1a65d1eceedf0"
  name   = local.name
  cidr   = "16.0.0.0/16"
  azs    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  private_subnets      = ["16.0.0.0/20", "16.0.16.0/20", "16.0.32.0/20"]
  private_subnet_names = ["private-eu-west-1a-dev", "private-eu-west-1b-dev", "private-eu-west-1c-dev"]

  enable_nat_gateway = false

  # VPC Flow Logs (Cloudwatch log group and IAM role will be created)
  enable_flow_log                      = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60

  tags = var.tags
  private_subnet_tags = {
    network = "Private"
  }
  private_route_table_tags = {
    network = "Private"
  }

}


module "endpoints_dev" {
  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc_dev.vpc_id
  create_security_group      = true
  security_group_description = "PPUD dev - Managed by Terraform"
  security_group_tags        = { Name : "eu-west-1-${local.name}" }
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc_dev.vpc_cidr_block]
    }
  }
  endpoints = {
    # interface endpoints  need  subnet_ids and sg_id
    # Interface endpoint for ec2messages
    logs = {
      service      = "logs"
      service_type = "Interface"
      tags         = { Name = "logs-api-vpc-endpoint-${local.name}" }
    }

    # ssmmessages = {
    #   service             = "ssmmessages"
    #   service_type        = "Interface"
    #   subnet_ids          = module.vpc_dev.private_subnets
    #   private_dns_enabled = true
    #   tags                = { Name = "ssmmessages-eu-west-1-${local.name}" }
    # }

    # ssm = {
    #   service             = "ssm"
    #   service_type        = "Interface"
    #   subnet_ids          = module.vpc_dev.private_subnets
    #   private_dns_enabled = true
    #   tags                = { Name = "ssm-eu-west-1-${local.name}" }
    # }


    s3 = {

      service_type    = "Gateway" # gateway endpoint
      service         = "s3"
      route_table_ids = module.vpc_dev.private_route_table_ids
      tags            = { Name = "s3-eu-west-1-${local.name}" }
    }

    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = module.vpc_dev.private_subnets
      private_dns_enabled = true
      tags                = { Name = "secretsmanager-eu-west-1-${local.name}" }
    }

    glue = {
      service             = "glue"
      service_type        = "Interface"
      subnet_ids          = module.vpc_dev.private_subnets
      private_dns_enabled = true
      tags                = { Name = "glue-eu-west-1-${local.name}" }
    }

    # sts = {
    #   service             = "sts"
    #   service_type        = "Interface"
    #   subnet_ids          = module.vpc_dev.private_subnets
    #   private_dns_enabled = true
    #   tags                = { Name = "sts-eu-west-1-${local.name}" }
    # }

  }


  tags = merge(var.tags, { network = "Private" })

}
