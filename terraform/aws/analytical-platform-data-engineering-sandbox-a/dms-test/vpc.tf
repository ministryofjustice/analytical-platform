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

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
  private_subnet_tags = {
    SubnetType = "Private"
  }
}
