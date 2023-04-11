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
    }
  ]
}

module "users" {
  for_each = { for user in local.users : user.email => user }

  source = "./modules/user"
  name   = each.value.name
  email  = each.value.email
}
