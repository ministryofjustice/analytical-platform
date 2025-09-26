module "vpc" {
  source             = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=7c1f791efd61f326ed6102d564d1a65d1eceedf0"
  name               = "antony-vpc-sandbox-vpc"
  cidr               = "70.0.0.0/16"
  azs                = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets    = ["70.0.1.0/24", "70.0.2.0/24", "70.0.3.0/24"]
  enable_vpn_gateway = true

  tags = {
    terraform   = "true"
    Environment = "antony-vpc-sandbox"
  }
}

module "endpoints" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=507193ee659f6f0ecdd4a75107e59e2a6c1ac3cc"

  vpc_id                      = module.vpc.vpc_id
  create_security_group       = true
  security_group_description  = "endpoints security group"
  security_group_tags         = {Name = "endpoints-sg1"}
  security_group_rules        = {
    ingress_https = {
      description      = "Allow HTTPS traffic"
      cidr_blocks      = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
    s3 = {
      # interface endpoint
      service = "s3"
      tags    = { Name = "s3-vpc-endpoint" }
    },
    dynamodb = {
      # gateway endpoint
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = ["rt-12322456", "rt-43433343", "rt-11223344"]
      tags            = { Name = "dynamodb-vpc-endpoint" }
    },
    sns = {
      service    = "sns"
      subnet_ids = ["subnet-12345678", "subnet-87654321"]
      subnet_configurations = [
        {
          ipv4      = "10.8.34.10"
          subnet_id = "subnet-12345678"
        },
        {
          ipv4      = "10.8.35.10"
          subnet_id = "subnet-87654321"
        }
      ]
      tags = { Name = "sns-vpc-endpoint" }
    },
    sqs = {
      service             = "sqs"
      private_dns_enabled = true
      security_group_ids  = ["sg-987654321"]
      subnet_ids          = ["subnet-12345678", "subnet-87654321"]
      tags                = { Name = "sqs-vpc-endpoint" }
    },
  }

  tags = {
    terraform   = "true"
    Environment = "antony-vpc-sandbox"
  }
}
