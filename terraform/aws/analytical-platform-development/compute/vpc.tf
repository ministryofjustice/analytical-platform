module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name                = local.vpc_name
  azs                 = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr                = "10.0.0.0/16"
  database_subnets    = ["10.0.1.0/26", "10.0.1.64/26", "10.0.1.128/26"]
  elasticache_subnets = ["10.0.2.0/26", "10.0.2.64/26", "10.0.2.128/26"]
  intra_subnets       = ["10.0.3.0/26", "10.0.3.64/26", "10.0.3.128/26"]
  private_subnets     = ["10.0.128.0/19", "10.0.160.0/19", "10.0.192.0/19"]
  public_subnets      = ["10.0.0.0/26", "10.0.0.64/26", "10.0.0.128/26"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_kms_key_id        = module.vpc_flow_logs_kms.key_arn
  flow_log_cloudwatch_log_group_retention_in_days = 400
  flow_log_max_aggregation_interval               = 60
}
