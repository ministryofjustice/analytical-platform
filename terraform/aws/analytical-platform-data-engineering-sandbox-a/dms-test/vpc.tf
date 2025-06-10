locals {
  name = "test-dms"
  tags = {
    business-unit    = "HMPPS"
    application      = "Data Engineering"
    environment-name = "sandbox"
    is-production    = "False"
    owner            = "DMET"
    team-name        = "DMET"
    namespace        = "dmet-test"
  }
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = local.name
  cidr = "10.0.0.0/16"
  azs  = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false

  tags = local.tags
  private_subnet_tags = {
    SubnetType = "Private"
  }
}
module "endpoints" {
  # Commit has for v5.21.0
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "Managed by Terraform"
  security_group_tags        = { Name : "eu-west-1-sandbox" }
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }
  endpoints = {
    # interface endpoints  need  subnet_ids and sg_id
    # Interface endpoint for ec2messages
    ec2messages = {
      service             = "ec2messages"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }

    ssmmessages = {
      service             = "ssmmessages"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }

    ssm = {
      service             = "ssm"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }


    s3 = {
      service_type    = "Gateway" # gateway endpoint
      service         = "s3"
      route_table_ids = module.vpc.private_route_table_ids
    }

    secrets_manager = {
      service             = "secretsmanager"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }

    glue = {
      service             = "glue"
      service_type        = "Interface"
      subnet_ids          = module.vpc.private_subnets
      private_dns_enabled = true
    }

  }

  tags = merge(local.tags, { network = "Private" })

}