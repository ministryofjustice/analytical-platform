locals {

  accounts = {
    data             = "593291632749",
    dev              = "525294151996",
    prod             = "312423030077",
    data_engineering = "189157455002",
    security         = "110958189132",
    landing          = "335823981503",
    management       = "042130406152",
    sandbox          = "684969100054",
    dev_data         = "803963757240",
    mi_dev           = "967617145656"
  }
  tags = {
    business-unit = "Platforms"
    project       = "data-platform-oidc"
    owner         = "data-platform"
    is-production = "true"
    source-code   = "github.com/ministryofjustice/data-platform/tree/main/terraform/oidc"
  }
  oidc-roles = jsondecode(file("${path.module}/github-oidc-assumable-roles-config.json"))

  deployment-roles = {
    "github-actions-infrastructure" = {
      description = "Allows GitHub Actions and self-hosted runners to administer this account",
      trusts      = {},
    },
    "data-engineering-infrastructure" = {
      description = "Deploys data engineering infrastructure",
      trusts = {
        name     = "github-actions-infrastructure",
        accounts = ["data", "data_engineering"]
      }
    }
  }

  additional_repos_for_ecr = ["analytics-platform-rshiny", "analytics-platform-auth-proxy"]
  # Application Migration -- needed to manage trust policy of the ECR management role

  ap_migration_apps  = jsondecode(file("../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each
}
