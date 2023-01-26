locals {

  # GitHub usernames for the Data Platform team maintainers
  # NB: Terraform shows a perputal difference in roles if someone is an organisation owner
  # and will attempt to change them from `maintainer` to `member`, so owners should go in here.
  maintainers = [
    "julialawrence",
    "jhackett-ap", # John Hackett
    "bagg3rs"      # Richard Baguley
  ]

  # GitHub usernames for CI users
  ci_users = [
    "mojanalytics"
  ]

  # All GitHub team maintainers
  all_maintainers = concat(local.maintainers, local.ci_users)

  # GitHub usernames for team members who don't need full AWS access
  general_members = [
    "jacobwoffenden",
    "calumabarnett",
    "ahbensiali",       # Abdel Bensiali
    "Bhkol",            # Bharti Kolhe - BA Cognizant
    "charlesvictor1107" # Charles Victor - Cognizant
  ]

  # GitHub usernames for engineers who need full AWS access
  engineers = [
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

  tech_archs_maintainers = [
    "jemnery", # Jeremy Collins
    "bagg3rs", # Richard Baguley
    "julialawrence"
  ]

  tech_archs_members = [
    "AlexVilela"
  ]
  # All Technical Architects
  tech_archs = concat(local.tech_archs_members, local.tech_archs_maintainers)

  # All members
  all_members = concat(local.general_members, local.engineers)

  # Everyone
  everyone = concat(local.all_maintainers, local.all_members)

  # Create a list of repositories that we want our customers to be able to contribute to
  analytical_platform_repositories = [
    for s in data.github_repositories.analytical-platform-repositories.names : s if startswith(s, "analytics-platform-")
  ]
}
