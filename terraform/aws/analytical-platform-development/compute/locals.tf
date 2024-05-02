locals {
  vpc_name                                = "development"
  vpc_flow_logs_cloudwatch_log_group_name = "/aws/vpc/${local.vpc_name}/flow-logs"

  eks_cluster_name              = "development"
  eks_cloudwatch_log_group_name = "/aws/eks/${local.eks_cluster_name}/cluster"
  eks_sso_access_role           = "AdministratorAccess"
}
