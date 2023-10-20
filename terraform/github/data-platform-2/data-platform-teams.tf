locals {
  users_with_special_github_access = ["julialawrence"]
  data_platform_teams = {
    "data-platform-user-centered-design" = {
      name           = "data-platform-user-centered-design"
      description    = "Data Platform User Centered Design"
      parent_team_id = module.data_platform_team.id
      members = [
        "gfowler-moj",      # Greg Fowler
        "RNTjustice",       # Richard Trist
        "alex-vonfeldmann", # Alex von Feldmann
        "hrahim-moj",       # Haymon Rahim
        "f-marry",          # Fabien Marry
        "seanprivett",      # Sean Privett
        "Ed-Bajo",          # Edwin Bajomo
      ]
    }
    "data-platform-apps-and-tools" = {
      name           = "data-platform-apps-and-tools"
      description    = "Data Platform Apps and Tools"
      parent_team_id = module.data_platform_team.id
      members = [
        "bagg3rs",           # Richard Baguley
        "AlexVilela",        # Alex Vilela
        "julialawrence",     # Julia Lawrence
        "jhpyke",            # Jacob Hamblin-Pyke
        "jacobwoffenden",    # Jacob Woffenden
        "Gary-H9",           # Gary Henderson
        "Emterry",           # Emma Terry
        "ymao2",             # Yikang Mao
        "michaeljcollinsuk", # Michael Collins
        "BrianEllwood",      # Brian Ellwood
        "murad-ali-MoJ",     # Murad Ali
        "EO510",             # Eki Osehenye
      ]
    },
    "data-platform-labs" = {
      name           = "data-platform-labs"
      description    = "Data Platform Labs"
      parent_team_id = module.data_platform_team.id
      members = [
        "jemnery",         # Jeremy Collins
        "PriyaBasker23",   # Priya Basker
        "YvanMOJdigital",  # Yvan Smith
        "LavMatt",         # Matt Laverty
        "murdo-moj",       # Murdo Moyse
        "tom-webber",      # Tom Webber
        "mitchdawson1982", # Mitch Dawson
        "MatMoore",        # Mat Moore
      ]
    },
    "data-platform-audit-and-security" = {
      name           = "data-platform-audit-and-security"
      description    = "Data Platform Audit and Security"
      parent_team_id = module.data_platform_team.id
      members = [
        "SimonsMOJ", # Simon Heron
      ]
    }
    "data-platform-cloud-platform-development" = {
      name           = "data-platform-cloud-platform-development"
      description    = "Data Platform Cloud Platform Development"
      parent_team_id = module.data_platform_team.id
      members = [
        "jacobwoffenden",  # Jacob Woffenden
        "julialawrence",   # Julia Lawrence
        "Gary-H9",         # Gary Henderson
        "jhpyke",          # Jacob Hamblin-Pyke
        "PriyaBasker23",   # Priya Basker
        "mitchdawson1982", # Mitch Dawson
        "murdo-moj",       # Murdo Moyse
      ]
    },
    "data-platform-cloud-platform-production" = {
      name           = "data-platform-cloud-platform-production"
      description    = "Data Platform Cloud Platform Production"
      parent_team_id = module.data_platform_team.id
      members = [
        "jacobwoffenden", # Jacob Woffenden
        "julialawrence",  # Julia Lawrence
      ]
    }
  }
  data_platform_all_teams_members = flatten([
    for team_name, team_data in local.data_platform_teams : [
      lookup(team_data, "members", [])
    ]
  ])
  data_platform_apps_and_tools_teams = {
    "data-platform-apps-and-tools-airflow-users" = {
      name           = "data-platform-apps-and-tools-airflow-users"
      description    = "Data Platform Apps and Tools Airflow Users"
      parent_team_id = module.data_platform_teams["data-platform-apps-and-tools"].id
      members = [
        "jacobwoffenden", # Jacob Woffenden
        "jhpyke",         # Jacob Hamblin-Pyke
      ]
    },
    "data-platform-apps-and-tools-sagemaker-users" = {
      name           = "data-platform-apps-and-tools-sagemaker-users"
      description    = "Data Platform Apps and Tools SageMaker Users"
      parent_team_id = module.data_platform_teams["data-platform-apps-and-tools"].id
      members = [
        "jacobwoffenden", # Jacob Woffenden
        "Gary-H9",        # Gary Henderson
        "ymao2",          # Yikang Mao
      ]
    }
  }
}

# Parent Team
module "data_platform_team" {
  source = "./modules/team"

  name                             = "data-platform"
  description                      = "Data Platform"
  members                          = local.data_platform_all_teams_members
  users_with_special_github_access = local.users_with_special_github_access
}

# Child Teams
module "data_platform_teams" {
  source = "./modules/team"

  for_each = { for team in local.data_platform_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = each.value.parent_team_id
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}

# Apps and Tools Teams
module "data_platform_apps_and_tools_teams" {
  source = "./modules/team"

  for_each = { for team in local.data_platform_apps_and_tools_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = each.value.parent_team_id
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}
