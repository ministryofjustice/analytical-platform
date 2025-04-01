module "eks_log_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.1"

  name              = "/aws/eks/${local.eks_cluster_name}/logs"
  kms_key_id        = module.eks_cluster_logs_kms.key_arn
  retention_in_days = 400
}

module "managed_prometheus_log_group" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
  version = "5.7.1"

  name              = "/aws/amp/analytical-platform-production"
  kms_key_id        = module.managed_prometheus_logs_kms.key_arn
  retention_in_days = 400
}
