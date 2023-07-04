locals {
  oidc_roles = jsondecode(file("${path.module}/configuration/assumable-roles.json"))

  deployment_roles = {
    "github-actions-infrastructure" = {
      description = "Allows GitHub Actions and self-hosted runners to administer this account",
      trusts      = {},
    },
    "data-engineering-infrastructure" = {
      description = "Deploys data engineering infrastructure",
      trusts = {
        name = "github-actions-infrastructure",
        accounts = [
          "analytical-platform-data-production",
          "analytical-platform-data-engineering-production"
        ]
      }
    }
  }

  additional_repos_for_ecr = ["analytics-platform-rshiny", "analytics-platform-auth-proxy"]

  ap_migration_apps  = jsondecode(file("../../../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each
}
