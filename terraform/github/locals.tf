locals {
  core_repos = [{ # Legacy Analytical Platform Internal Infrastructure Repos in the MOJ org
    name        = "ap-terraform-bootstrap",
    description = "Bootstrap for setting up analytical platform and data engineering accounts"
    },
    {
      name        = "analytics-platform-infrastructure",
      description = "Core Infrastructure Repo for Data Platform"
    },
    {
      name        = "ap-test-github-workflow",
      description = "Test repository for github docker workflow"
  }]

  data_platform_repos = [{ # Repos to Support the Buildout of the Data Platform
    name        = "data-platform",
    description = "Core Repo for Data Platform"
    },
    {
      name        = "data-platform-products",
      description = "Core Repository for Data Platform Data Products"
    },
    {
      name        = "data-platform-support",
      description = "Core Repository for Data Platform Support"
    }
  ]
  ap_migration_apps  = jsondecode(file("./ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each

  # migration_apps_teams = [for app in local.ap_migration_apps : app.team]

  migration_apps_teams_map = {for app in local.ap_migration_apps : app.team => app.name...}

  cloud_platform_eks_oidc_provider_arn = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"
  cloud_platform_eks_oidc_provider_id  = "oidc.eks.eu-west-2.amazonaws.com/id/DF366E49809688A3B16EEC29707D8C09"

  # All Tech Archs
  tech_archs = concat(local.tech_archs_members, local.tech_archs_maintainers)

  # All Data Engineers
  all_members_data_engineers = concat(
    local.data_engineering_maintainers,
    local.data_engineering_members,
    local.data_engineering_aws_members
  )

  all_members_data_platform_core_infrastructure = concat(
    local.data_platform_core_infrastructure_maintainers,
    local.data_platform_core_infrastructure_members
  )

  all_members_data_platform_labs = concat(
    local.data_platform_labs_maintainers,
    local.data_platform_labs_members
  )

  # All members
  all_members = concat(local.general_members, local.engineers)

  # Everyone
  # commented out to satisfy tflint
  # everyone = concat(local.all_maintainers, local.all_members)
}
