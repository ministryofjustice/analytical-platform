locals {

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

    # GitHub usernames for CI users
  ci_users = [
    "mojanalytics",
    "moj-data-platform-robot"
  ]
}
