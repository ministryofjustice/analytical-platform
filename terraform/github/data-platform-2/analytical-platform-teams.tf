locals {
  analytical_platform_all_teams_members = flatten([
    for team_name, team_data in local.analytical_platform_teams : [
      lookup(team_data, "members", [])
    ]
  ])

  analytical_platform_teams = {
    "analytics-hq" = {
      name           = "analytics-hq"
      description    = "Analytics HQ"
      parent_team_id = module.analytical_platform_team.id
      members = [
        "julialawrence",     # Julia Lawrence
        "bagg3rs",           # Richard Baguley
        "jacobwoffenden",    # Jacob Woffenden
        "calumabarnett",     # Calum Barnett
        "SimonsMOJ",         # Simon Heron
        "mshodge",           # Michael Hodges
        "YvanMOJdigital",    # Yvan Smith
        "EO510",             # Eki Osehenye
        "f-marry",           # Fabien Marry
        "alex-vonfeldmann",  # Alex von Feldmann
        "gfowler-moj",       # Greg Fowler
        "RNTjustice",        # Richard Trist,
        "ymao2",             # Yikang Mao
        "BrianEllwood",      # Brian Ellwood
        "Emterry",           # Emma Terry
        "michaeljcollinsuk", # Michael Collins
        "jhpyke",            # Jacob Hamblin-Pyke
        "murad-ali-MoJ",     # Murad Ali
        "Gary-H9",           # Gary Henderson
        "mitchdawson1982",   # Mitch Dawson
        "bagg3rs"            # Richard Baguley
      ]
    }
  }
}

module "analytical_platform_team" {
  source = "./modules/team"

  name                             = "analytical-platform"
  description                      = "Analytical Platform"
  members                          = local.analytical_platform_all_teams_members
  parent_team_id                   = module.data_platform_team.id
  users_with_special_github_access = local.users_with_special_github_access
}

module "analytical_platform_teams" {
  source = "./modules/team"

  for_each = { for team in local.analytical_platform_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = each.value.parent_team_id
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}
