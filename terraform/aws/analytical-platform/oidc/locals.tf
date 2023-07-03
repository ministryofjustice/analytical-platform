locals {
  tags = {
    business-unit = "Platforms"
    project       = "data-platform-oidc"
    owner         = "data-platform"
    is-production = "true"
    source-code   = "github.com/ministryofjustice/data-platform/tree/main/terraform/oidc"
  }

  oidc_roles = jsondecode(file("${path.module}/configuration/assumable-roles.json"))

  deployment-roles = {
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
  # Application Migration -- needed to manage trust policy of the ECR management role

  ap_migration_apps  = jsondecode(file("../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each
}
