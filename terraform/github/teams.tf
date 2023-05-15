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
  # TFLINT has this variable as unused
  # all_maintainers = concat(local.maintainers, local.ci_users)

  # GitHub usernames for team members who don't need or are not cleared for full AWS access

  general_members = [ # members of analytics-hq gh team
    "jacobwoffenden",
    "calumabarnett",
    "SimonsMOJ",      # Simon Heron
    "mshodge",        # Michael Hodges
    "YvanMOJdigital", # Yvan Smith
    "amycufflin",
    "ChikC",    # Chike Chinukwue
    "EO510",    # Eki Osehenye
    "Braimah-L" # Braimah Lat
  ]

  # GitHub usernames for engineers who need full AWS access

  engineers = [ # analytical-platform and analytics-hq gh teams
    "LouiseABowler",
    "ymao2", # Yikang Mao
    "andyrogers1973",
    "BrianEllwood",
    "tom-webber",
    "bogdan-mania-moj",
    "Emterry", # Emma Terry
    "michaeljcollinsuk",
    "jhpyke",
    "tamsinforbes",
    "murad-ali-j"
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
    "hemeshpatel-moj",
    "ChikC" # Chike Chinukwue
  ]

  # DATA-ENGINEERING-AWS GITHUB GROUP WITH FULL AWS ACCESS

  data_engineering_aws_members = [
    "Mamonu",        # Theodoros Manassis
    "mratford",      # Mike Ratford
    "Danjiv",        # Danjiv Ramkhalawon
    "K1Br",          # Kimberley Brett
    "vonbraunbates", # Francesca von Braun-Bates
    "AnthonyCody",
    "tamsinforbes", # Tamsin Forbes
    "gwionap",
    "tmpks", # Tapan P
    "Thomas-Hirsch",
    "LavMatt",
    "williamorrie", # William Orr
    "gustavmoller",
    "jhpyke",         # Jake Hamblin-Pyke
    "lalithanagarur", # Lalitha Nagarur (Cog)
    "murad-ali-j",    # Murad Ali
    "Bharat-Dhiman",  # Bharat Dhiman (Cog)
    "mdowniecog",     # Michael Downie (Cog)
    "oliver-critchfield",
    "AlexVilela",
    "davidbridgwood",
    "mshodge", # Michael Hodge
    "Andy-Cook",
    "samnlindsay",
    "ThomasHepworth",
    "zslade",
    "ADBond",
    "aliceoleary0"
  ]

  data_engineering_aws_developer_members = [
    "parminder-thindal-moj",
    "moj-samuelweller"
  ]

  data_platform_core_infrastructure_maintainers = [
    "bagg3rs", # Richard Baguley
    "julialawrence",
    "jacobwoffenden"
  ]

  data_platform_core_infrastructure_members = [
    "jhackett-ap", # John Hackett
    "Emterry",     # Emma Terry
    "jhpyke",
    "tamsinforbes",
    "murad-ali-j"
  ]

  data_platform_labs_maintainers = [
    "PriyaBasker23",
  ]

  data_platform_labs_members = [
    "hemeshpatel-moj",
    "murdo-moj",
    "LavMatt"
  ]

  data_platform_security_auditor_members = [
    "simonsMOJ",
    "julialawrence",
    "jacobwoffenden"
  ]
}
