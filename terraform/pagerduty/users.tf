locals {
  users = [
    {
      name  = "Andy Rogers"
      email = "andy.rogers@digital.justice.gov.uk"
    },
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
      name  = "Tom Webber"
      email = "thomas.webber@digital.justice.gov.uk"
    },
    {
      name  = "Brian Ellwood"
      email = "brian.ellwood@digital.justice.gov.uk"
    },
    {
      name  = "Louise Bowler"
      email = "louise.bowler@digital.justice.gov.uk"
    },
    {
      name  = "Bogdan Mania"
      email = "bogdan.mania@digital.justice.gov.uk"
    },
    {
      name  = "John Hackett"
      email = "john.hackett@digital.justice.gov.uk"
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
      name  = "Mitch Dawson"
      email = "mitch.dawson@digital.justice.gov.uk"
    }
  ]
}

module "users" {
  for_each = { for user in local.users : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.value.email
}
