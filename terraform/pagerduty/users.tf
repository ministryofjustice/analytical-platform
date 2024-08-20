locals {
  users = [
    {
      name  = "Emma Terry"
      email = "emma.terry@digital.justice.gov.uk"
    },
    {
      name  = "Jacob Woffenden"
      email = "jacob.woffenden@digital.justice.gov.uk"
    },
    {
      name  = "Julia Lawrence"
      email = "julia.lawrence@digital.justice.gov.uk"
    },
    {
      name  = "Richard Baguley"
      email = "richard.baguley@digital.justice.gov.uk"
    },
    {
      name  = "Brian Ellwood"
      email = "brian.ellwood@digital.justice.gov.uk"
    },
    {
      name  = "Michael Collins"
      email = "michael.collins@digital.justice.gov.uk"
    },
    {
      name  = "Gary Henderson"
      email = "gary.henderson@digital.justice.gov.uk"
    },
    {
      name  = "Jacob Hamblin-Pyke"
      email = "jacob.hamblin-pyke@digital.justice.gov.uk"
    },
    {
      name  = "James Stott"
      email = "james.stott@digital.justice.gov.uk"
    },
    {
      name  = "Anthony Fitzroy"
      email = "anthony.fitzroy@digital.justice.gov.uk"
    },
    {
      name  = "Yvan Smith"
      email = "yvan.smith@digital.justice.gov.uk"
    }
  ]
}

module "users" {
  for_each = { for user in local.users : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.value.email
}

import {
  to = module.users["yvan.smith@digital.justice.gov.uk"].pagerduty_user.this
  id = "PWEB0DB"
}
