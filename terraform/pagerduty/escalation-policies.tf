locals {
  escalation_policies = [
    {
      name                        = "Analytical Platform"
      team                        = module.teams["Analytical Platform"].id
      num_loops                   = 2
      rules = [
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "schedule_reference"
              id   = module.schedules["Analytical Platform"].id
            }
          ]
        },
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "user_reference"
              id   = module.users["jacob.woffenden@digital.justice.gov.uk"].id
            }
          ]
        }
      ]
    },
    {
      name                        = "Data Platform"
      team                        = module.teams["Data Platform"].id
      num_loops                   = 2
      rules = [
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "schedule_reference"
              id   = module.schedules["Data Platform"].id
            }
          ]
        },
        {
          escalation_delay_in_minutes = 15
          targets = [
            {
              type = "user_reference"
              id   = module.users["jacob.woffenden@digital.justice.gov.uk"].id
            }
          ]
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
  rules                       = each.value.rules

  depends_on = [
    module.schedules,
    module.teams
  ]
}
