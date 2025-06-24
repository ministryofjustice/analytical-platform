resource "helm_release" "grafana" {
  /* https://artifacthub.io/packages/helm/grafana/grafana */
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "9.2.7"
  namespace  = var.namespace
  values = [
    templatefile(
      "${path.module}/src/helm/values/grafana/values.yml.tftpl",
      {
        namespace           = var.namespace,
        github_organisation = "ministryofjustice",
        github_admin_team   = "analytical-platform-engineers",
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

  set_sensitive {
    name  = "env.GF_AUTH_GITHUB_CLIENT_ID"
    value = data.aws_secretsmanager_secret_version.analytical_platform_grafana_production_github_client_id.secret_string
  }
  set_sensitive {
    name  = "env.GF_AUTH_GITHUB_CLIENT_SECRET"
    value = data.aws_secretsmanager_secret_version.analytical_platform_grafana_production_github_client_secret.secret_string
  }
  set_sensitive {
    name  = "env.ANALYTICAL_PLATFORM_SLACK_TOKEN"
    value = data.aws_secretsmanager_secret_version.analytical_platform_slack_token.secret_string
  }
}
