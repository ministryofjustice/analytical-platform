#trivy:ignore:avd-aws-0102 NACLs not restricted
#trivy:ignore:avd-aws-0105 NACLs not restricted
module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name            = local.vpc_name
  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  cidr            = local.vpc_cidr
  private_subnets = local.vpc_private_subnets

  enable_nat_gateway = false

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_name_prefix       = local.vpc_flow_log_cloudwatch_log_group_name_prefix
  flow_log_cloudwatch_log_group_name_suffix       = local.vpc_flow_log_cloudwatch_log_group_name_suffix
  flow_log_cloudwatch_log_group_kms_key_id        = module.vpc_flow_logs_kms.key_arn
  flow_log_cloudwatch_log_group_retention_in_days = local.vpc_flow_log_cloudwatch_log_group_retention_in_days
  flow_log_max_aggregation_interval               = local.vpc_flow_log_max_aggregation_interval
  vpc_flow_log_tags                               = { Name = local.vpc_name }
}
