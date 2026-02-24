##################################################
# AWS
##################################################

data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_region" "current" {}

data "aws_region" "sqs_region" {
  provider = aws.control-panel-sqs-region
}

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
  provider  = aws.analytical-platform-management-production
  secret_id = "pagerduty/analytical-platform-compute/integration-keys/cloudwatch"
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_networking_cloudwatch_integration_key" {
  provider  = aws.analytical-platform-management-production
  secret_id = "pagerduty/analytical-platform-networking/integration-keys/cloudwatch"
}

data "aws_secretsmanager_secret_version" "pagerduty_analytical_platform_storage_cloudwatch_integration_key" {
  provider  = aws.analytical-platform-management-production
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

##################################################
# Prometheus CRDs
##################################################

data "http" "prometheus_operator_crds" {
  for_each = {
    alertmanagerconfigs = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml"
    alertmanagers       = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml"
    podmonitors         = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml"
    probes              = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml"
    prometheus_agents   = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml"
    prometheuses        = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml"
    prometheusrules     = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml"
    scrapeconfigs       = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml"
    servicemonitors     = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml"
    thanosrulers        = "https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.77.2/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml"
  }

  url = each.value
}

##################################################
# Modernisation Platform Core Logging
##################################################

data "aws_route53_resolver_query_log_config" "core_logging_s3" {
  filter {
    name   = "Name"
    values = ["core-logging-rlq-s3-eu-west-1"]
  }
}
