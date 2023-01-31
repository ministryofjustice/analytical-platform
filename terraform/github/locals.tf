locals {

  # GitHub usernames for the Data Platform team maintainers
  # NB: Terraform shows a perputal difference in roles if someone is an organisation owner
  # and will attempt to change them from `maintainer` to `member`, so owners should go in here.

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
  maintainers = [ # maintainers of analytics-hq and analytical-platform gh teams
    "julialawrence",
    "rossjones",
    "jhackett-ap", # John Hackett
    "bagg3rs"      # Richard Baguley
  ]

  # GitHub usernames for CI users
  ci_users = [
    "mojanalytics"
  ]

  # All GitHub team maintainers
  all_maintainers = concat(local.maintainers, local.ci_users)

  # GitHub usernames for team members who don't need or are not cleared for full AWS access
  general_members = [ # members of analytics-hq gh team
    "jacobwoffenden",
    "calumabarnett",
    "ahbensiali",        # Abdel Bensiali
    "Bhkol",             # Bharti Kolhe - BA Cognizant
    "charlesvictor1107", # Charles Victor - Cognizant
    "Emterry"            # Emma Terry
  ]

  # GitHub usernames for engineers who need full AWS access
  engineers = [ # analytical-platform and analytics-hq gh teams
    "LouiseABowler",
    "ymao2", # Yeking Mao
    "andyrogers1973",
    "BrianEllwood",
    "tom-webber",
    "bogdan-mania-moj",
    "dominqs",      # Dominic Simpson - Cognizant
    "sreekanthmoj", # Sreekanth Kote - Cognizant
    "karthikmoj",   # Karthik Pelluru - Cognizant
  ]

  tech_archs_maintainers = [ # maintainers of data-tech-archs gh group
    "rossjones",
    "jemnery", # Jeremy Collins
    "bagg3rs", # Richard Baguley
    "julialawrence"
  ]

  tech_archs_members = [ # members of the data-tech-archs gh group
    "AlexVilela"
  ]
  # All Technical Architects
  tech_archs = concat(local.tech_archs_members, local.tech_archs_maintainers)

  data_engineering_maintainers = [
    "calumabarnett",
    "SoumayaMauthoorMOJ",
    "PriyaBasker23"
  ]

  data_engineering_members = [
    "Mamonu",   #Danjiv Ramkhalawon
    "mratford", # Mike Ratford
    "Danjiv",   # theodoros.manassis
    "K1Br",
    "vonbraunbates", # Francessca von Braun-Bates
    "AnthonyCody",
    "tamsinforbes", # Tamsin Forbes
    "gwionap",
    "tmpks", # Tapan P
    "Thomas-Hirsch",
    "LavMatt",
    "williamorrie", # William Orr
    "gustavmoller",
    "jhpyke", # Jake H Pyke
    "makl3",
    "oliver-critchfield",
    "AlexVilela"
  ]

  # All data engineers

  all_members_data_engineers = concat(local.data_engineering_maintainers, local.data_engineering_members)

  # All members
  all_members = concat(local.general_members, local.engineers)

  # Everyone
  everyone = concat(local.all_maintainers, local.all_members)

  # Create a list of repositories that we want our customers to be able to contribute to
  analytical_platform_repositories = [
    for s in data.github_repositories.analytical-platform-repositories.names : s if startswith(s, "analytics-platform-")
  ]
}