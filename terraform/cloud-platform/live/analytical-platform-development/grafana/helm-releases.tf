resource "helm_release" "grafana" {
  /* https://artifacthub.io/packages/helm/grafana/grafana */
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "8.11.4"
  namespace  = var.namespace
  values = [
    templatefile(
      "${path.module}/src/helm/values/grafana/values.yml.tftpl",
      {
        github_client_id     = data.aws_secretsmanager_secret_version.analytical_platform_grafana_development_github_client_id.secret_string
        github_client_secret = data.aws_secretsmanager_secret_version.analytical_platform_grafana_development_github_client_secret.secret_string
        github_organisation  = "ministryofjustice"
        github_admin_team    = "analytical-platform-engineers"
        github_team_ids = join(",", [
          data.github_team.analytical_platform_engineers.id,
          data.github_team.analytical_platform_airflow.id,
          data.github_team.data_engineering.id
        ])
      }
    )
  ]
}

# To retrieve a team ID, you need to do the following:
# $ aws-sso exec --profile analytical-platform-management-production:AdministratorAccess
# $ GH_TOKEN=$(aws --region eu-west-1 secretsmanager get-secret-value --secret-id github-token | jq -r '.SecretString') gh api /orgs/ministryofjustice/teams/${TEAM_NAME} | jq -r '.id'
# analytical-platform-engineers: 12120135
# analytical-platform-airflow:   12120137
# data-engineering:              8205153
