locals {
  # ---------------------------------------------------------------------------
  # Grafana dashboards are defined in JSON files under:
  #   src/helm/values/grafana/dashboards/<folder>/<dashboard-name>.json
  #
  #   <folder>          -> becomes both the Grafana UI folder the dashboard
  #                         appears under (used as-is, e.g. "data-platform")
  #                         and its own provisioning provider/mount path.
  #   <dashboard-name>  -> becomes the dashboard's key in that provider
  #                         (the .json extension is stripped).
  #
  # To add a dashboard: drop its exported JSON under the right <folder>
  # (or a new one) and `terraform apply` — no code changes required.
  #
  # ---------------------------------------------------------------------------
  dashboards_root = "${path.module}/src/helm/values/grafana/dashboards"

  # every dashboard JSON file on disk, one level of subfolders deep
  dashboard_file_paths = fileset(local.dashboards_root, "**/*.json")

  # distinct subfolder names -> one Grafana folder + provider per subfolder
  dashboard_folders = distinct([for f in local.dashboard_file_paths : dirname(f)])

  dashboard_provider_keys = {
    for folder in local.dashboard_folders :
    folder => replace(folder, "/", "-")
  }

  dashboards_by_provider = {
    for folder in local.dashboard_folders :
    local.dashboard_provider_keys[folder] => {
      for f in local.dashboard_file_paths :
      trimsuffix(basename(f), ".json") => {
        json = sensitive(file("${local.dashboards_root}/${f}"))
      }
      if dirname(f) == folder
    }
  }

  dashboard_providers = [
    for folder in sort(local.dashboard_folders) : {
      name            = local.dashboard_provider_keys[folder]
      orgId           = 1
      folder          = folder
      type            = "file"
      disableDeletion = false
      editable        = false
      options = {
        path = "/var/lib/grafana/dashboards/${local.dashboard_provider_keys[folder]}"
      }
    }
  ]

  dashboard_providers_yaml = {
    "dashboardproviders.yaml" = {
      apiVersion = 1
      providers  = local.dashboard_providers
    }
  }
}
