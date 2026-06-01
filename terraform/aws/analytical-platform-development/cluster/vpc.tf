##################################################
# VPC
##################################################

module "vpc" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name                    = "${var.environment}-vpc"
  cidr                    = var.vpc_cidr
  azs                     = data.aws_availability_zones.available.names
  private_subnets         = var.vpc_private_subnets
  public_subnets          = var.vpc_public_subnets
  database_subnets        = var.vpc_database_subnets
  enable_nat_gateway      = true
  single_nat_gateway      = false
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  enable_flow_log                                 = true
  flow_log_traffic_type                           = "ALL"
  flow_log_destination_type                       = "cloud-watch-logs"
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_cloudwatch_log_group_retention_in_days = 400

  # Manage default NACL and apply VPN restrictions
  manage_default_network_acl = true

  default_network_acl_ingress = concat(
    [
      {
        rule_no    = 100
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = "-1"
        cidr_block = var.vpc_cidr
      }
    ],
    [
      for index, cidr in var.moj_vpn_cidrs : {
        rule_no    = 101 + index
        action     = "allow"
        from_port  = 0
        to_port    = 0
        protocol   = "-1"
        cidr_block = cidr
      }
    ]
  )

  default_network_acl_egress = [
    {
      rule_no    = 100
      action     = "allow"
      from_port  = 0
      to_port    = 0
      protocol   = "-1"
      cidr_block = "0.0.0.0/0"
    }
  ]

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                          = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                 = "1"
    "karpenter.sh/discovery"                          = local.eks_cluster_name
  }
}
