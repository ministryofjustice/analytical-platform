locals {
  finance_team_all_teams_members = flatten([
    for team_name, team_data in local.finance_team : [
      lookup(team_data, "members", [])
    ]
  ])

  finance_team = {
    "finance-team" = {
      name           = "finance-team"
      description    = "Finance Team"
      parent_team_id = module.data_platform_team.id
      members = [
        "Gary-H9" # Gary Henderson
      ]
    }
  }
}

module "data_platform_finance_team" {
  source = "./modules/team"

  for_each = { for team in local.finance_team : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = each.value.parent_team_id
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}
