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
          data.github_team.data_engineering.id,
          data.github_team.probation_data_science.id,
          data.github_team.probation_integration.id
        ])
      }
    )
  ]
}
