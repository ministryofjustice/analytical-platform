##################################################
# Control Panel Redis
##################################################

module "control_panel_redis" {
  source  = "cloudposse/elasticache-redis/aws"
  version = "0.52.0"

  enabled                    = var.redis_enabled
  replication_group_id       = local.redis_replication_group_id
  engine_version             = var.redis_engine_version
  family                     = var.redis_family
  auth_token                 = local.redis_credentials.auth_token
  instance_type              = var.redis_instance_type
  cluster_size               = var.redis_cluster_size
  vpc_id                     = module.vpc.vpc_id
  availability_zones         = data.aws_availability_zones.available.names
  subnets                    = module.vpc.private_subnets
  stage                      = var.environment
  namespace                  = var.redis_namespace
  at_rest_encryption_enabled = var.redis_at_rest_encryption_enabled
  automatic_failover_enabled = var.redis_automatic_failover_enabled
  multi_az_enabled           = var.redis_multi_az_enabled

  cloudwatch_metric_alarms_enabled = true
  alarm_actions                    = [aws_sns_topic.analytical_platform_storage_alerts.arn]
  ok_actions                       = [aws_sns_topic.analytical_platform_storage_alerts.arn]
  alarm_cpu_threshold_percent      = var.redis_alarm_cpu_threshold_percent
  alarm_memory_threshold_bytes     = var.redis_alarm_memory_threshold_bytes

  security_group_description = "Security group for Control panel Redis"
  allowed_security_groups    = [module.eks.worker_security_group_id]
}
