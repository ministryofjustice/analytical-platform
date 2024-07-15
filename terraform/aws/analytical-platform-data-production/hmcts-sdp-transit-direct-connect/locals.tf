locals {
  /* VPC */
  vpc_name = "mojap-hmcts-sdp-transit-vpc"

  vpc_cidr = "10.27.128.0/21"
  vpc_private_subnets = [
    "10.27.128.0/26",
    "10.27.128.64/26",
    "10.27.128.128/26"
  ]

  vpc_flow_log_cloudwatch_log_group_name_prefix       = "/aws/vpc-flow-log/"
  vpc_flow_log_cloudwatch_log_group_name_suffix       = local.vpc_name
  vpc_flow_log_cloudwatch_log_group_retention_in_days = 400
  vpc_flow_log_max_aggregation_interval               = 60
}
