# module "container_insights_log_group" {
#   source  = "terraform-aws-modules/cloudwatch/aws//modules/log-group"
#   version = "5.3.1"

#   name              = "/aws/containerinsights/${local.eks_cluster_name}"
#   kms_key_id        = module.container_insights_logs_kms.key_arn
#   retention_in_days = 400
# }
