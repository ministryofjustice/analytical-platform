#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_AWS_356:Module managed policy
  #checkov:skip=CKV_AWS_111:Module managed policy
  #checkov:skip=CKV2_AWS_11:This is not production infrastructure
  #checkov:skip=CKV2_AWS_12:This is not production infrastructure
  #checkov:skip=CKV2_AWS_19:This is not production infrastructure

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "open-metadata"

  cidr                = "10.123.0.0/16"
  azs                 = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets     = ["10.123.0.0/24", "10.123.1.0/24", "10.123.2.0/24"]
  public_subnets      = ["10.123.10.0/24", "10.123.11.0/24", "10.123.12.0/24"]
  intra_subnets       = ["10.123.20.0/24", "10.123.21.0/24", "10.123.22.0/24"]
  database_subnets    = ["10.123.30.0/24", "10.123.31.0/24", "10.123.32.0/24"]
  elasticache_subnets = ["10.123.40.0/24", "10.123.41.0/24", "10.123.42.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
