locals {
  escalation_policies = [
    {
      name                        = "Analytical Platform"
      team                        = module.teams["Analytical Platform"].id
      num_loops                   = 2
      escalation_delay_in_minutes = 10
      targets = [
        {
          type = "schedule_reference"
          id   = module.schedules["Analytical Platform"].id
        }
      ]
    },
    {
      name                        = "Data Platform"
      team                        = module.teams["Data Platform"].id
      num_loops                   = 2
      escalation_delay_in_minutes = 10
      targets = [
        {
          type = "schedule_reference"
          id   = module.schedules["Data Platform"].id
        }
      ]
    }
  ]
}

module "escalation_policies" {
  for_each = { for escalation_policy in local.escalation_policies : escalation_policy.name => escalation_policy }

  source                      = "./modules/escalation-policy"
  name                        = each.key
  team                        = each.value.team
  num_loops                   = each.value.num_loops
  escalation_delay_in_minutes = each.value.escalation_delay_in_minutes
  targets                     = each.value.targets

  depends_on = [
    module.schedules,
    module.teams
  ]
}
