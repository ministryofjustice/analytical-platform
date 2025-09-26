module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=7c1f791efd61f326ed6102d564d1a65d1eceedf0"
  name               = "antony-vpc-sandbox-vpc"
  cidr               = "10.173.0.0/16"
  azs                = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets    = ["10.173.174.0/24", "10.173.175.0/24", "10.173.176.0/24"]
  enable_vpn_gateway = true

  tags = var.tags
}

module "endpoints" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                     = module.vpc.vpc_id
  create_security_group      = true
  security_group_description = "endpoints security group"
  security_group_tags        = { Name = "endpoints-sg1" }
  security_group_rules = {
    ingress_https = {
      description = "Allow HTTPS traffic"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      # interface endpoint
      service         = "s3"
      tags            = { Name = "s3-vpc-interface" }
      service_type    = "Interface"
      route_table_ids = module.vpc.private_subnets
    },
    s3 = {
      # gateway endpoint
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_subnets
      tags            = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      # gateway endpoint
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_subnets
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    sns = {
      service    = "sns"
      subnet_ids = module.vpc.private_subnets
      subnet_configurations = [
        {
          ipv4      = "10.173.174.0/24"
          subnet_id = "eu-west-2a"
        },
        {
          ipv4      = "10.173.175.0/24"
          subnet_id = "eu-west-2b"
        }
      ]
      tags = { Name = "sns-vpc-endpoint" }
    },
    sqs = {
      service             = "sqs"
      private_dns_enabled = true
      security_group_ids  = [aws_security_group.database.id]
      subnet_ids          = module.vpc.private_subnets
      tags                = { Name = "sqs-vpc-endpoint" }
    }
  }

  tags = var.tags
}
