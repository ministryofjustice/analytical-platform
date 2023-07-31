##################################################
# VPC
##################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

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
