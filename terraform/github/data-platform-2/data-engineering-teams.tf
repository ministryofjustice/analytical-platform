locals {
  data_engineering_all_teams_members = flatten([
    for team_name, team_data in local.data_engineering_teams : [
      lookup(team_data, "members", [])
    ]
  ])

  data_engineering_teams = {}
}

module "data_engineering_team" {
  source = "./modules/team"

  name                             = "data-engineering"
  description                      = "Data Engineering"
  members                          = local.data_engineering_all_teams_members
  parent_team_id                   = data.github_team.data_and_analytics_engineering.id
  users_with_special_github_access = local.users_with_special_github_access
}
