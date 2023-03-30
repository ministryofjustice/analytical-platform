locals {
  technical_services = [
    {
      name                    = "Analytical Platform High Priority"
      description             = "High priority incidents for the Analytical Platform team"
      escalation_policy       = module.escalation_policies["Analytical Platform"].id
    },
    {
      name                    = "Analytical Platform Low Priority"
      description             = "Low priority incidents for the Analytical Platform team"
      escalation_policy       = module.escalation_policies["Analytical Platform"].id
    },
    {
      name                    = "Data Platform High Priority"
      description             = "High priority incidents for the Data Platform team"
      escalation_policy       = module.escalation_policies["Data Platform"].id
      auto_pause_notifications_parameters = [
        {
          enabled = true
          timeout = 600
        }
      ]
      support_hours = [
        {
          type         = "fixed_time_per_day"
          start_time   = "09:00:00"
          end_time     = "17:00:00"
          time_zone    = "Europe/London"
          days_of_week = [1, 2, 3, 4, 5]
        }
      ]
      incident_urgency_rules = [
        {
          type    = "use_support_hours"
          during_support_hours = [
            {
              type    = "constant"
              urgency = "high"
            }
          ]
          outside_support_hours = [
            {
              type    = "constant"
              urgency = "low"
            }
          ]
        }
      ]
      enable_cloudwatch_integration = true
      enable_github_integration     = true
    },
    {
      name                    = "Data Platform Low Priority"
      description             = "Low priority incidents for the Data Platform team"
      escalation_policy       = module.escalation_policies["Data Platform"].id
    }
  ]

}

module "technical_services" {
  for_each = { for technical_service in local.technical_services : technical_service.name => technical_service }

  source                              = "./modules/service/technical"
  name                                = each.key
  description                         = each.value.description
  escalation_policy                   = each.value.escalation_policy
  alert_creation                      = try(each.value.alert_creation, "create_alerts_and_incidents")
  auto_resolve_timeout                = try(each.value.auto_resolve_timeout, 14400)
  acknowledgement_timeout             = try(each.value.acknowledgement_timeout, 600)
  incident_urgency_rules               = try(each.value.incident_urgency_rules, [])
  auto_pause_notifications_parameters = try(each.value.auto_pause_notifications_parameters, [])
  support_hours                       = try(each.value.support_hours, [])
  enable_cloudwatch_integration       = try(each.value.enable_cloudwatch_integration, false)
  enable_github_integration           = try(each.value.enable_github_integration, false)

  depends_on = [module.escalation_policies]
}
