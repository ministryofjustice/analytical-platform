locals {
  maintainers = [ # maintainers of analytics-hq and analytical-platform gh teams
    "julialawrence",
    "jhackett-ap", # John Hackett
    "bagg3rs"      # Richard Baguley
  ]

  # GitHub usernames for CI users
  ci_users = [
    "mojanalytics",
    "moj-data-platform-robot"
  ]

  # All GitHub team maintainers
  all_maintainers = concat(local.maintainers, local.ci_users)

  # GitHub usernames for team members who don't need or are not cleared for full AWS access

  general_members = [ # members of analytics-hq gh team
    "jacobwoffenden",
    "calumabarnett",
    "Bhkol",         # Bharti Kolhe - BA Cognizant
    "SimonsMOJ",     # Simon Heron
    "mshodge",       # Michael Hodges
    "YvanMOJdigital" # Yvan Smith
  ]

  # GitHub usernames for engineers who need full AWS access

  engineers = [ # analytical-platform and analytics-hq gh teams
    "LouiseABowler",
    "ymao2", # Yikang Mao
    "andyrogers1973",
    "BrianEllwood",
    "tom-webber",
    "bogdan-mania-moj",
    "sreekanthmoj", # Sreekanth Kote - Cognizant
    "karthikmoj",   # Karthik Pelluru - Cognizant
    "Emterry",      # Emma Terry
    "ahbensiali"    # Abdel Bensiali
  ]

  tech_archs_maintainers = [ # maintainers of data-tech-archs gh group
    "jemnery",               # Jeremy Collins
    "bagg3rs",               # Richard Baguley
    "julialawrence"
  ]

  tech_archs_members = [ # members of the data-tech-archs gh group
    "AlexVilela"
  ]

  data_engineering_maintainers = [
    "calumabarnett",
    "SoumayaMauthoorMOJ",
    "PriyaBasker23",
    "julialawrence"
  ]

  # DATA-ENGINEERING GITHUB GROUP WITH SANDBOX-ONLY ACCESS

  data_engineering_members = [
    "lalithanagarur",
    "Bharat-Dhiman",
    "mdowniecog",
    "pjxcog",
    "sivabathina2",
    "hemeshpatel-moj"
  ]

  # DATA-ENGINEERING-AWS GITHUB GROUP WITH FULL AWS ACCESS

  data_engineering_aws_members = [
    "Mamonu",        # Theodoros Manassis
    "mratford",      # Mike Ratford
    "Danjiv",        # Danjiv Ramkhalawon
    "K1Br",          # Kimberley Brett
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
    "AlexVilela",
    "davidbridgwood",
    "mshodge" # Michael Hodge
  ]

  data_platform_core_infrastructure_maintainers = [
    "bagg3rs", # Richard Baguley
    "julialawrence",
    "jacobwoffenden"
  ]

  data_platform_core_infrastructure_members = [
    "jhackett-ap",  # John Hackett
    "Bhkol",        # Bharti Kolhe - BA Cognizant
    "sreekanthmoj", # Sreekanth Kote - Cognizant
    "karthikmoj",   # Karthik Pelluru - Cognizant
    "Emterry",      # Emma Terry
  ]
}
