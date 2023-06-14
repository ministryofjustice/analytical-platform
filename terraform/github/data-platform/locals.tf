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
  ap_migration_apps  = jsondecode(file("../../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each
  # migration_apps_teams = [for app in local.ap_migration_apps : app.team]

  team_repo_list = flatten([
    for repo, details in data.github_repository_teams.migration_apps_repo_owners : [
      for team in details.teams : {
        team = team.name
        repo = one([for app in local.migration_apps_map : app.name if app.source_repo_name == details.name])
      }
    ]
  ])

  unique_old_teams_names = distinct([for item in local.team_repo_list : item.team])

  team_repo_map = {
    for item in local.unique_old_teams_names :
    item => distinct([for i in local.team_repo_list : i.repo if i.team == item])
  }

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
