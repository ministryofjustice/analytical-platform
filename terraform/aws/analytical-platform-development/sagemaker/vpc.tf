#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_AWS_356:Module managed policy
  #checkov:skip=CKV_AWS_111:Module managed policy
  #checkov:skip=CKV2_AWS_11:This is not production infrastructure
  #checkov:skip=CKV2_AWS_12:This is not production infrastructure
  #checkov:skip=CKV2_AWS_19:This is not production infrastructure

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "sagemaker"

  cidr            = "10.124.0.0/16"
  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets  = ["10.124.10.0/24", "10.124.11.0/24", "10.124.12.0/24"]
  private_subnets = ["10.124.0.0/24", "10.124.1.0/24", "10.124.2.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = false

}
