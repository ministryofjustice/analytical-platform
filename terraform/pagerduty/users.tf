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
      name  = "Yikang Mao"
      email = "yikang.mao@justice.gov.uk"
    },
    {
      name  = "Gary Henderson"
      email = "gary.henderson@digital.justice.gov.uk"
    },
    {
      name  = "Alex Vilela"
      email = "alex.vilela@digital.justice.gov.uk"
    },
    {
      name  = "Jacob Hamblin-Pyke"
      email = "jacob.hamblin-pyke@digital.justice.gov.uk"
    },
    {
      name  = "Murad Ali"
      email = "murad.ali@digital.justice.gov.uk"
    }
  ]
}

module "users" {
  for_each = { for user in local.users : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.value.email
}
