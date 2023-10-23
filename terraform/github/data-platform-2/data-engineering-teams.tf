locals {
  data_engineering_team_members = [
    "calumabarnett",      # Calum Barnett
    "PriyaBasker23",      # Priya Basker
    "SoumayaMauthoorMOJ", # Soumaya Mauthoor
    "mamonu",             # Theodoros Manassis
    "mratford",           # Mike Ratford
    "Danjiv",             # Danjiv Ramkhalawon
    "K1Br",               # Kimberley Brett
    "vonbraunbates",      # Francesca von Braun-Bates
    "AnthonyCody",        # Anthony Cody
    "gwionap",            # Gwion ApRhobat
    "tmpks",              # Tapan Perkins
    "Thomas-Hirsch",      # Thomas Hirsch
    "LavMatt",            # Matt Laverty
    "williamorrie",       # William Orr
    "gustavmoller",       # Gustav Moller
    "jhpyke",             # Jake Hamblin-Pyke
    "murad-ali-MoJ",      # Murad Ali
    "oliver-critchfield", # Oliver Critchfield
    "AlexVilela",         # Alex Vilela
    "davidbridgwood",     # David Bridgwood
    "mshodge",            # Michael Hodge
    "Andy-Cook",          # Andy Cook
    "samnlindsay",        # Sam Lindsay
    "ThomasHepworth",     # Thomas Hepworth
    "zslade",             # Zoe Slade
    "ADBond",             # Andrew Bond
    "aliceoleary0",       # Alice O'Leary
    "RossKen",            # Ross Kennedy
    "afua-moj",           # Afua Kokayi
    "murdo-moj",          # Murdo Moyse
    "matmoore",           # Mat Moore
    "AntFMoJ",            # Anthony Fitzroy
    "tomholt1",           # Tom Holt
    "lalithanagarur",     # Lalitha Nagarur
    "sivabathina2",       # Siva Bathina
    "hemeshpatel-moj",    # Hemesh Patel
  ]
}

module "data_engineering_team" {
  source = "./modules/team"

  name                             = "data-engineering"
  description                      = "Data Engineering"
  members                          = local.data_engineering_team_members
  parent_team_id                   = data.github_team.data_and_analytics_engineering.id
  users_with_special_github_access = local.users_with_special_github_access
}
