locals {
  escalation_policies = [
    {
      name        = "Analytical Platform"
      description = "Escalation policy for the Analytical Platform team"
      team        = module.teams["Analytical Platform"].id
      num_loops   = 2
      rules = [
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "schedule_reference"
              id   = module.schedules["Analytical Platform"].id
            }
          ]
        }
      ]
    },
    {
      name        = "Data Platform"
      description = "Escalation policy for the Data Platform team"
      team        = module.teams["Data Platform"].id
      num_loops   = 2
      rules = [
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "schedule_reference"
              id   = module.schedules["Data Platform"].id
            }
          ]
        }
      ]
    }
  ]
}

module "escalation_policies" {
  for_each = { for escalation_policy in local.escalation_policies : escalation_policy.name => escalation_policy }

  source      = "./modules/escalation-policy"
  name        = each.key
  description = each.value.description
  team        = each.value.team
  num_loops   = each.value.num_loops
  rules       = each.value.rules

  depends_on = [
    module.schedules,
    module.teams
  ]
}
