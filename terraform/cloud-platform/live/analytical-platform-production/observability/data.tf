data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_cluster_ca_cert" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/cluster/ca-cert"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_cluster_endpoint" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/cluster/endpoint"
}

data "aws_secretsmanager_secret_version" "cloud_platform_live_analytical_platform_production_token" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/analytical-platform-production/token"
}

data "aws_secretsmanager_secret_version" "github_token" {
  provider = aws.analytical-platform-management-production-eu-west-1

  secret_id = "github-token"
}

data "github_team" "analytical_platform_engineers" {
  slug = "analytical-platform-engineers"
}

data "github_team" "analytical_platform_airflow" {
  slug = "analytical-platform-airflow"
}

data "github_team" "data_engineering" {
  slug = "data-engineering"
}

data "github_team" "probation_data_science" {
  slug = "probation-data-science"
}

data "github_team" "probation_integration" {
  slug = "probation-integration"
}

data "aws_secretsmanager_secret_version" "analytical_platform_grafana_production_github_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "analytical-platform-grafana/production/github/client-id"
}

data "aws_secretsmanager_secret_version" "analytical_platform_grafana_production_github_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "analytical-platform-grafana/production/github/client-secret"
}

data "aws_secretsmanager_secret_version" "analytical_platform_slack_token" {
  provider = aws.analytical-platform-management-production

  secret_id = "slack/analytical-platform"
}
