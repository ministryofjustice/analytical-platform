locals {
  data_platform_all_teams_members = flatten([
    for team_name, team_data in local.data_platform_teams : [
      lookup(team_data, "members", [])
    ]
  ])

  data_platform_teams = {
    "data-platform-user-centered-design" = {
      name           = "data-platform-user-centered-design"
      description    = "Data Platform User Centered Design"
      parent_team_id = module.data_platform_team.id
      members = [
        "gfowler-moj",      # Greg Fowler
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
        "julialawrence",     # Julia Lawrence
        "jhpyke",            # Jacob Hamblin-Pyke
        "jacobwoffenden",    # Jacob Woffenden
        "Gary-H9",           # Gary Henderson
        "Emterry",           # Emma Terry
        "michaeljcollinsuk", # Michael Collins
        "BrianEllwood",      # Brian Ellwood
        "murad-ali-MoJ",     # Murad Ali
        "EO510",             # Eki Osehenye
        "AntFMoJ",           # Anthony Fitzroy
        "mitchdawson1982",   # Mitch Dawson
      ]
    },
    "data-platform-labs" = {
      name           = "data-platform-labs"
      description    = "Data Platform Labs"
      parent_team_id = module.data_platform_team.id
      members = [
        "jemnery",         # Jeremy Collins
        "PriyaBasker23",   # Priya Basker
        "seanprivett",     # Sean Privett
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
    },
    /* Legacy */
    "data-platform-core-infra" = {
      name           = "data-platform-core-infra"
      description    = "Data Platform Core Infrastructure"
      parent_team_id = module.data_platform_team.id
      members = [
        "bagg3rs",           # Richard Baguley
        "julialawrence",     # Julia Lawrence
        "jhpyke",            # Jacob Hamblin-Pyke
        "jacobwoffenden",    # Jacob Woffenden
        "Gary-H9",           # Gary Henderson
        "Emterry",           # Emma Terry
        "michaeljcollinsuk", # Michael Collins
        "BrianEllwood",      # Brian Ellwood
        "murad-ali-MoJ",     # Murad Ali
        "EO510",             # Eki Osehenye
      ]
    }
  }

  data_platform_cloud_platform_teams = {
    "data-platform-cloud-platform-development" = {
      name        = "data-platform-cloud-platform-development"
      description = "Data Platform Cloud Platform Development"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members
      ])
    },
    "data-platform-cloud-platform-production" = {
      name        = "data-platform-cloud-platform-production"
      description = "Data Platform Cloud Platform Production"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    }
  }

  data_platform_modernisation_platform_teams = {
    "data-platform-development-sandbox" = {
      name        = "data-platform-development-sandbox"
      description = "Data Platform Development Sandbox"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members
      ])
    },
    "data-platform-preproduction-developer" = {
      name        = "data-platform-preproduction-developer"
      description = "Data Platform PreProduction Developer"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members
      ])
    },
    "data-platform-production-developer" = {
      name        = "data-platform-production-developer"
      description = "Data Platform Production Developer"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members
      ])
    },
    "data-platform-test-developer" = {
      name        = "data-platform-test-developer"
      description = "Data Platform Test Developer"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members
      ])
    },
    "data-platform-apps-and-tools-development-sandbox" = {
      name        = "data-platform-apps-and-tools-development-sandbox"
      description = "Data Platform Apps and Tools Development Sandbox"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "data-platform-apps-and-tools-production-developer" = {
      name        = "data-platform-apps-and-tools-production-developer"
      description = "Data Platform Apps and Tools Production Developer"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    }
  }

  data_platform_apps_and_tools_teams = {
    "data-platform-apps-and-tools-airflow-users" = {
      name        = "data-platform-apps-and-tools-airflow-users"
      description = "Data Platform Apps and Tools Airflow Users"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "data-platform-apps-and-tools-sagemaker-users" = {
      name        = "data-platform-apps-and-tools-sagemaker-users"
      description = "Data Platform Apps and Tools SageMaker Users"
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "data-platform-apps-and-tools-powerbi-authors" = {
      name           = "data-platform-apps-and-tools-powerbi-authors"
      description    = "Data Platform Apps and Tools PowerBI Authors"
      parent_team_id = module.data_platform_teams["data-platform-apps-and-tools"].id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        "andrewc-moj", # Andrew Craik
        "gwionap"      # Gwion ApRhobat
      ])
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
  parent_team_id                   = try(each.value.parent_team_id, null)
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}

# Cloud Platform Access Teams
module "data_platform_cloud_platform_teams" {
  source = "./modules/team"

  for_each = { for team in local.data_platform_cloud_platform_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = try(each.value.parent_team_id, null)
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}

# Modernisation Platform Access Teams
module "data_platform_modernisation_platform_teams" {
  source = "./modules/team"

  for_each = { for team in local.data_platform_modernisation_platform_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = try(each.value.parent_team_id, null)
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}

# Apps and Tools Teams
module "data_platform_apps_and_tools_teams" {
  source = "./modules/team"

  for_each = { for team in local.data_platform_apps_and_tools_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = try(each.value.parent_team_id, null)
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}
