locals {
  teams = [
    {
      name = "Analytical Platform"
      managers = [
        module.users["emma.terry@digital.justice.gov.uk"].id,
        module.users["jacob.woffenden@digital.justice.gov.uk"].id,
        module.users["julia.lawrence@digital.justice.gov.uk"].id
      ]
    },
    {
      name       = "Data Engineering"
      managers   = []
      responders = []
    },
    {
      name = "Data Platform"
      managers = [
        module.users["emma.terry@digital.justice.gov.uk"].id,
        module.users["jacob.woffenden@digital.justice.gov.uk"].id,
        module.users["julia.lawrence@digital.justice.gov.uk"].id
      ]
    }
  ]
}

module "teams" {
  for_each = { for team in local.teams : team.name => team }

  source     = "./modules/team"
  name       = each.key
  managers   = try(each.value.managers, [])
  responders = try(each.value.responders, [])

  depends_on = [module.users]
}
