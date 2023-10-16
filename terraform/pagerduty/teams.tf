locals {
  teams = [
    {
      name = "Data Platform"
      managers = [
        module.users["jacob.woffenden@digital.justice.gov.uk"].id,
        module.users["julia.lawrence@digital.justice.gov.uk"].id,
        module.users["richard.baguley@digital.justice.gov.uk"].id
      ]
      responders = [
        module.users["emma.terry@digital.justice.gov.uk"].id,
        module.users["brian.ellwood@digital.justice.gov.uk"].id,
        module.users["michael.collins@digital.justice.gov.uk"].id,
        module.users["yikang.mao@justice.gov.uk"].id,
        module.users["gary.henderson@digital.justice.gov.uk"].id,
        module.users["alex.vilela@digital.justice.gov.uk"].id,
        module.users["jacob.hamblin-pyke@digital.justice.gov.uk"].id,
        module.users["murad.ali@digital.justice.gov.uk"].id
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
