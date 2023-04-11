locals {
  teams = [
    {
      name = "Analytical Platform"
      managers = [
        module.users["julia.lawrence@digital.justice.gov.uk"].id,
        module.users["richard.baguley@digital.justice.gov.uk"].id
      ]
      responders = [
        module.users["thomas.webber@digital.justice.gov.uk"].id,
        module.users["brian.ellwood@digital.justice.gov.uk"].id,
        module.users["louise.bowler@digital.justice.gov.uk"].id,
        module.users["bogdan.mania@digital.justice.gov.uk"].id,
        module.users["john.hackett@digital.justice.gov.uk"].id,
        module.users["michael.collins@digital.justice.gov.uk"].id,
        module.users["yikang.mao@justice.gov.uk"].id
      ]
    },
    {
      name = "Data Platform"
      managers = [
        module.users["jacob.woffenden@digital.justice.gov.uk"].id,
        module.users["julia.lawrence@digital.justice.gov.uk"].id,
        module.users["richard.baguley@digital.justice.gov.uk"].id
      ]
      responders = [
        module.users["andy.rogers@digital.justice.gov.uk"].id,
        module.users["emma.terry@digital.justice.gov.uk"].id
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
