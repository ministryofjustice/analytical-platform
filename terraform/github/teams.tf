locals {
  maintainers = [ # maintainers of analytics-hq and analytical-platform gh teams
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

  # GitHub usernames for team members who don't need or are not cleared for full AWS access

  general_members = [ # members of analytics-hq gh team
    "jacobwoffenden",
    "calumabarnett",
    "ahbensiali",        # Abdel Bensiali
    "Bhkol",             # Bharti Kolhe - BA Cognizant
    "charlesvictor1107", # Charles Victor - Cognizant
    "dominqs",           # Dominic Simpson - Cognizant
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
    "Emterry"       # Emma Terry
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
    "PriyaBasker23"
  ]

  # DATA-ENGINEERING GITHUB GROUP

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
}
