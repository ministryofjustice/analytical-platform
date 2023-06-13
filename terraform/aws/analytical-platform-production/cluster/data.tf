##################################################
# AWS
##################################################

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

data "aws_route53_zone" "main" {
  name         = var.route53_zone
  private_zone = false
}

data "aws_iam_roles" "aws_sso_administrator_access" {
  name_regex  = "AWSReservedSSO_${var.aws_sso_role_prefix}_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_secretsmanager_secret_version" "auth0_credentials" {
  secret_id = "${var.environment}/auth0-terraform/auth0-creds"
}

data "aws_secretsmanager_secret_version" "control_panel_redis" {
  secret_id = "${var.environment}/control-panel-redis"
}

data "aws_secretsmanager_secret_version" "control_panel_rds_db_password" {
  secret_id = "${var.environment}/control-panel-db-password"
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_compute_cloudwatch_integration_key" {
  provider  = aws.management-production
  secret_id = "pagerduty/analytical-platform-compute/integration-keys/cloudwatch"
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_networking_cloudwatch_integration_key" {
  provider  = aws.management-production
  secret_id = "pagerduty/analytical-platform-networking/integration-keys/cloudwatch"
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_storage_cloudwatch_integration_key" {
  provider  = aws.management-production
  secret_id = "pagerduty/analytical-platform-storage/integration-keys/cloudwatch"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_nat_gateways" "nat_gateways" {
  vpc_id = module.vpc.vpc_id

  filter {
    name   = "state"
    values = ["available"]
  }
}

##################################################
# TLS
##################################################

data "tls_certificate" "cross_account_irsa_oidc_issuer" {
  url = module.eks.cluster_oidc_issuer_url
}
