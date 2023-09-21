locals {
  maintainers = [ # maintainers of analytics-hq and analytical-platform gh teams
    "julialawrence",
    "bagg3rs" # Richard Baguley
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
    "SimonsMOJ",        # Simon Heron
    "mshodge",          # Michael Hodges
    "YvanMOJdigital",   # Yvan Smith
    "ChikC",            # Chike Chinukwue
    "EO510",            # Eki Osehenye
    "Braimah-L",        # Braimah Lat
    "imkatiewatson",    # Katie Watson
    "f-marry",          # Fabien Marry
    "alex-vonfeldmann", # Alex von Feldmann
    "gfowler-moj",      # Greg Fowler
    "RNTjustice"        # Richard Trist
  ]

  # GitHub usernames for engineers who need full AWS access

  engineers = [ # analytical-platform and analytics-hq gh teams
    "ymao2",    # Yikang Mao
    "BrianEllwood",
    "tom-webber",
    "Emterry", # Emma Terry
    "michaeljcollinsuk",
    "jhpyke",
    "tamsinforbes",
    "murad-ali-MoJ",
    "Gary-H9",
    "mitchdawson1982",
    "bagg3rs" # Richard Baguley
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
    "pjxcog",
    "sivabathina2",
    "hemeshpatel-moj",
    "ChikC",      # Chike Chinukwue
    "hrahim-moj", # Haymon
    "lalithanagarur"
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
    "jhpyke",        # Jake Hamblin-Pyke
    "murad-ali-MoJ", # Murad Ali
    "oliver-critchfield",
    "AlexVilela",
    "davidbridgwood",
    "mshodge", # Michael Hodge
    "Andy-Cook",
    "samnlindsay",
    "ThomasHepworth",
    "zslade",
    "ADBond",
    "aliceoleary0",
    "RossKen",
    "afua-moj",
    "murdo-moj",
    "matmoore",
    "AntFMoJ",  # Anthony Fitzroy
    "tomholt1", # Tom Holt
    "lalithanagarur",
    "sivabathina2"
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
    "Emterry", # Emma Terry
    "jhpyke",
    "murad-ali-MoJ",
    "tamsinforbes",
    "tom-webber",
    "mitchdawson1982",
    "Gary-H9"
  ]

  data_platform_labs_maintainers = [
    "PriyaBasker23",
  ]

  data_platform_labs_members = [
    "murdo-moj",
    "matmoore",
    "LavMatt",
    "tom-webber"
  ]

  data_platform_security_auditor_members = [
    "simonsMOJ",
    "julialawrence",
    "jacobwoffenden"
  ]
}
