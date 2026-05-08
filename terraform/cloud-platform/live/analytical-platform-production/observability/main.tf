locals {
  # Merge all environments into a single rules.yaml
  alert_rules_yaml = "groups:\n${join("\n", flatten([
    for env in keys(local.environment_configurations) :
    local.group_blocks_by_env[env]
  ]))}\n"
}

resource "kubernetes_config_map_v1" "grafana_alert_rules" {
  metadata {
    name      = "grafana-alert-rules"
    namespace = var.namespace
  }

  data = {
    "rules.yaml" = local.alert_rules_yaml
  }
}
