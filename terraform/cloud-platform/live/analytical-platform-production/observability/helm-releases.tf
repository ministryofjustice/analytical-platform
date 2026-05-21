resource "helm_release" "grafana" {
  /* https://artifacthub.io/packages/helm/grafana/grafana */
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = "10.5.15"
  namespace  = var.namespace
  depends_on = [kubernetes_config_map_v1.grafana_alert_rules]
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
        alert_rules_configmaps = {
          for env, cm in kubernetes_config_map_v1.grafana_alert_rules :
          env => cm.metadata[0].name
        }
        alert_rules_checksum = local.metrics_checksum
    }),
    yamlencode({
      podAnnotations = {
        "checksum/alert-rules" = local.metrics_checksum
      }
    })
  ]

  set_sensitive = [
    {
      name  = "env.GF_AUTH_GITHUB_CLIENT_ID"
      value = data.aws_secretsmanager_secret_version.analytical_platform_grafana_production_github_client_id.secret_string
    },
    {
      name  = "env.GF_AUTH_GITHUB_CLIENT_SECRET"
      value = data.aws_secretsmanager_secret_version.analytical_platform_grafana_production_github_client_secret.secret_string
    },
    {
      name  = "env.ANALYTICAL_PLATFORM_SLACK_TOKEN"
      value = data.aws_secretsmanager_secret_version.analytical_platform_slack_token.secret_string
    }
  ]
}
