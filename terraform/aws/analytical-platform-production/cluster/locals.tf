locals {
  auth0_credentials = jsondecode(data.aws_secretsmanager_secret_version.auth0_credentials.secret_string)

  cloud_platform_eks_oidc_url        = "https://oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
  cloud_platform_eks_oidc_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"

  efs_file_system_name = "eks-${var.environment}-user-homes"

  eks_cluster_name = "${var.environment}-${random_string.suffix.result}"

  pagerduty_analytical_platform_compute_endpoint    = "https://events.pagerduty.com/integration/${data.aws_secretsmanager_secret_version.pagerduty_analytical_platform_compute_cloudwatch_integration_key.secret_string}/enqueue"
  pagerduty_analytical_platform_networking_endpoint = "https://events.pagerduty.com/integration/${data.aws_secretsmanager_secret_version.pagerduty_analytical_platform_networking_cloudwatch_integration_key.secret_string}/enqueue"
  pagerduty_analytical_platform_storage_endpoint    = "https://events.pagerduty.com/integration/${data.aws_secretsmanager_secret_version.pagerduty_analytical_platform_storage_cloudwatch_integration_key.secret_string}/enqueue"

  rds_identifier  = "eks-${var.environment}-control-panel-psg-db-encrypted"
  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.control_panel_rds_db_password.secret_string)

  redis_replication_group_id = "${var.environment}-control-panel-redis"
  redis_credentials          = jsondecode(data.aws_secretsmanager_secret_version.control_panel_redis.secret_string)
}
