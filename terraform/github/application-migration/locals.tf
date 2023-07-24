locals {

  ap_migration_apps  = jsondecode(file("../../../configuration/ap_migration_apps.json"))
  migration_apps_map = { for app in local.ap_migration_apps : app.name => app } # so can be used in for_each
  # migration_apps_teams = [for app in local.ap_migration_apps : app.team]

  team_repo_list = flatten([
    for repo, details in data.github_repository_teams.migration_apps_repo_owners : [
      for team in details.teams : {
        team = lower(team.slug)
        repo = one([for app in local.migration_apps_map : app.name if app.source_repo_name == details.name])
      } if team.name != "everyone"
    ]
  ])

  unique_old_teams_names = distinct(flatten(concat(
    [for app in local.ap_migration_apps : [for team in app.team : lower(team)]],
    [for team_repo in local.team_repo_list : lower(team_repo.team)]
  )))

  team_repo_map = {
    for team_name in local.unique_old_teams_names : team_name => distinct(concat(flatten([
      for app in local.ap_migration_apps :
      contains(app.team, team_name) ? [app.name] : []
      ]), flatten([
      for team_repo in local.team_repo_list :
      team_repo.repo != null && team_repo.team == team_name ? [team_repo.repo] : []
    ])))

  }

  # GitHub usernames for CI users
  ci_users = [
    "mojanalytics",
    "moj-data-platform-robot"
  ]
}
