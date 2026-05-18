locals {
  alert_rules_yaml = yamlencode({
    groups = flatten([
      for env in keys(local.environment_configurations) :
      local.group_blocks_by_env[env]
    ])
  })
}

locals {
  metrics_checksum = sha256(jsonencode({
    golden_signals             = local.golden_signals
    defaults                   = local.defaults
    environment_configurations = local.environment_configurations
    alert_rules_yaml           = local.alert_rules_yaml
  }))
}

resource "kubernetes_config_map_v1" "grafana_alert_rules" {
  metadata {
    name      = "grafana-alert-rules"
    namespace = var.namespace

    annotations = {
      "checksum/rules" = local.metrics_checksum
    }
  }

  data = {
    "rules.yaml" = local.alert_rules_yaml
  }
}
