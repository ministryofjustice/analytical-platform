data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret" "cloud_platform_live_cluster_ca_cert" {
  provider = aws.analytical-platform-management-production

  name = "cloud-platform/live/cluster/ca-cert"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_cluster_ca_cert" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.cloud_platform_live_cluster_ca_cert.id
}

data "aws_secretsmanager_secret" "cloud_platform_live_cluster_endpoint" {
  provider = aws.analytical-platform-management-production

  name = "cloud-platform/live/cluster/endpoint"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_cluster_endpoint" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.cloud_platform_live_cluster_endpoint.id
}

data "aws_secretsmanager_secret" "cloud_platform_live_data_platform_production_token" {
  provider = aws.analytical-platform-management-production

  name = "cloud-platform/live/data-platform-production/token"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_data_platform_production_token" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.cloud_platform_live_data_platform_production_token.id
}
