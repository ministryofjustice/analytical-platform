module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name                   = local.name
  cidr                   = local.vpc_cidr
  azs                    = local.azs
  private_subnets        = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k + 1)]
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name = local.name
  }
}

resource "aws_cloudwatch_log_group" "data_engineering_vpc" {
  name       = "data_engineering_vpc_flow_logs"
  kms_key_id = aws_kms_key.data_engineering_vpc_key.arn
}

resource "aws_flow_log" "data_engineering_vpc" {
  log_destination = aws_cloudwatch_log_group.data_engineering_vpc.arn
  traffic_type    = "ALL"
  vpc_id          = module.vpc.vpc_id
}

resource "aws_kms_key" "data_engineering_vpc_key" {
  description             = "KMS Key for CloudWatch Logs Encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}
