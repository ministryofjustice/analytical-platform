locals {
  alert_rules_yaml_by_env = {
    for env in keys(local.environment_configurations) :
    env => yamlencode({
      groups = local.group_blocks_by_env[env]
    })
  }
}

locals {
  metrics_checksum = sha256(jsonencode({
    golden_signals             = local.golden_signals
    defaults                   = local.defaults
    environment_configurations = local.environment_configurations
    alert_rules_yaml_by_env    = local.alert_rules_yaml_by_env
  }))
}

resource "kubernetes_config_map_v1" "grafana_alert_rules" {
  for_each = local.environment_configurations

  metadata {
    name      = "grafana-alert-rules-${each.key}"
    namespace = var.namespace

    annotations = {
      "checksum/rules" = sha256(local.alert_rules_yaml_by_env[each.key])
    }
  }

  data = {
    "rules.yaml" = local.alert_rules_yaml_by_env[each.key]
  }
}
