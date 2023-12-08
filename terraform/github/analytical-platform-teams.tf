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
        "SimonsMOJ",         # Simon Heron
        "mshodge",           # Michael Hodges
        "YvanMOJdigital",    # Yvan Smith
        "EO510",             # Eki Osehenye
        "f-marry",           # Fabien Marry
        "alex-vonfeldmann",  # Alex von Feldmann
        "gfowler-moj",       # Greg Fowler
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

  analytical_platform_modernisation_platform_teams = {
    /* Analytical Platform */
    "analytical-platform-development-administrator" = {
      name           = "analytical-platform-development-administrator"
      description    = "Analytical Platform Development Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "analytical-platform-production-administrator" = {
      name           = "analytical-platform-production-administrator"
      description    = "Analytical Platform Production Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    /* Analytical Platform Data */
    "analytical-platform-data-development-administrator" = {
      name           = "analytical-platform-data-development-administrator"
      description    = "Analytical Platform Data Development Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        "tom-webber",
      ])
    },
    "analytical-platform-data-development-data-engineer" = {
      name           = "analytical-platform-data-development-data-engineer"
      description    = "Analytical Platform Data Development Data Engineer"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_engineering_team_members
      ])
    },
    "analytical-platform-data-production-administrator" = {
      name           = "analytical-platform-data-production-administrator"
      description    = "Analytical Platform Data Production Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "analytical-platform-data-production-data-engineer" = {
      name           = "analytical-platform-data-production-data-engineer"
      description    = "Analytical Platform Data Production Data Engineer"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_engineering_team_members
      ])
    },
    /* Analytical Platform Data Engineering */
    "analytical-platform-data-engineering-sandboxa-administrator" = {
      name           = "analytical-platform-data-engineering-sandboxa-administrator"
      description    = "Analytical Platform Data Engineering SandboxA Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members,
        local.data_platform_teams["data-platform-labs"].members,
        local.data_engineering_team_members
      ])
    },
    "analytical-platform-data-engineering-sandboxa-data-engineer" = {
      name           = "analytical-platform-data-engineering-sandboxa-data-engineer"
      description    = "Analytical Platform Data Engineering SandboxA Data Engineer"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-labs"].members,
        local.data_engineering_team_members
      ])
    },
    "analytical-platform-data-engineering-sandboxa-developer" = {
      name           = "analytical-platform-data-engineering-sandboxa-developer"
      description    = "Analytical Platform Data Engineering SandboxA Developer"
      parent_team_id = module.analytical_platform_team.id
      members        = flatten([])
    },
    "analytical-platform-data-engineering-production-administrator" = {
      name           = "analytical-platform-data-engineering-production-administrator"
      description    = "Analytical Platform Data Engineering Production Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    "analytical-platform-data-engineering-production-data-engineer" = {
      name           = "analytical-platform-data-engineering-production-data-engineer"
      description    = "Analytical Platform Data Engineering Production Data Engineer"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_engineering_team_members
      ])
    },
    "analytical-platform-data-engineering-production-developer" = {
      name           = "analytical-platform-data-engineering-production-developer"
      description    = "Analytical Platform Data Engineering Production Developer"
      parent_team_id = module.analytical_platform_team.id
      members        = flatten([])
    },
    /* Analytical Platform Landing */
    "analytical-platform-landing-production-administrator" = {
      name           = "analytical-platform-landing-production-administrator"
      description    = "Analytical Platform Landing Development Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    /* Analytical Platform Management */
    "analytical-platform-management-production-administrator" = {
      name           = "analytical-platform-management-production-administrator"
      description    = "Analytical Platform Management Development Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    },
    /* MI Platform */
    "mi-platform-development-administrator" = {
      name           = "mi-platform-development-administrator"
      description    = "MI Platform Development Administrator"
      parent_team_id = module.analytical_platform_team.id
      members = flatten([
        local.data_platform_teams["data-platform-apps-and-tools"].members
      ])
    }
  }
}

module "analytical_platform_team" {
  source = "./modules/team"

  name                             = "analytical-platform"
  description                      = "Analytical Platform"
  members                          = local.analytical_platform_all_teams_members
  parent_team_id                   = null
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

# Modernisation Platform Access Teams
module "analytical_platform_modernisation_platform_teams" {
  source = "./modules/team"

  for_each = { for team in local.analytical_platform_modernisation_platform_teams : team.name => team }

  name                             = each.value.name
  description                      = each.value.description
  parent_team_id                   = each.value.parent_team_id
  members                          = each.value.members
  users_with_special_github_access = local.users_with_special_github_access
}
