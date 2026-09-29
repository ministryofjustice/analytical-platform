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

data "aws_secretsmanager_secret_version" "cloud_platform_live_analytical_platform_development_token" {
  provider = aws.analytical-platform-management-production

  secret_id = "cloud-platform/live/analytical-platform-development/token"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "github_team" "analytical_platform_engineers" {
  slug = "analytical-platform-engineers"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "github_team" "analytical_platform_airflow" {
  slug = "analytical-platform-airflow"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "github_team" "data_engineering" {
  slug = "data-engineering"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "github_team" "probation_data_science" {
  slug = "probation-data-science"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "github_team" "probation_integration" {
  slug = "probation-integration"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "aws_secretsmanager_secret_version" "analytical_platform_grafana_development_github_client_id" {
  provider = aws.analytical-platform-management-production

  secret_id = "analytical-platform-grafana/development/github/client-id"
}

# tflint-ignore: terraform_unused_declarations -- only used by the commented-out helm_release.grafana in helm-releases.tf
data "aws_secretsmanager_secret_version" "analytical_platform_grafana_development_github_client_secret" {
  provider = aws.analytical-platform-management-production

  secret_id = "analytical-platform-grafana/development/github/client-secret"
}

