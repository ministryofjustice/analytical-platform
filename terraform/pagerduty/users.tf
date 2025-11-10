locals {
  users = [
    {
      name  = "Anthony Fitzroy"
      email = "anthony.fitzroy@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Brian Ellwood"
      email = "brian.ellwood@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "David Sibley"
      email = "david.sibley@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Gary Henderson"
      email = "gary.henderson@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Jacob Hamblin-Pyke"
      email = "jacob.hamblin-pyke@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Jacob Woffenden"
      email = "jacob.woffenden@digital.justice.gov.uk"
      role  = "manager"
    },
    {
      name  = "James Stott"
      email = "james.stott@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Julia Lawrence"
      email = "julia.lawrence@digital.justice.gov.uk"
      role  = "manager"
    },
    {
      name  = "Michael Collins"
      email = "michael.collins@digital.justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Tamsin Forbes"
      email = "tamsin.forbes@justice.gov.uk"
      role  = "responder"
    },
    {
      name  = "Theo Manassis"
      email = "theodoros.manassis@justice.gov.uk"
      role  = "responder"
    },
  ]
}


module "users" {
  for_each = { for user in local.users : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.key
}
