locals {
  technical_services = [
    {
      name              = "Analytical Platform"
      description       = "Generic alerts for the Analytical Platform"
      escalation_policy = module.escalation_policies["Analytical Platform"].id
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
          type = "use_support_hours"
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
      enable_email_integration = true
    },
    {
      name              = "Analytical Platform Security"
      description       = "Security alerts for the Analytical Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_cloudwatch_integration    = true
      enable_cloudtrail_integration    = true
      enable_guardduty_integration     = true
      enable_security_hub_integration  = true
      enable_email_integration         = true
      enable_alert_manager_integration = true
    },
    {
      name              = "Analytical Platform Networking"
      description       = "Networking alerts for the Analytical Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_email_integration      = true
    },
    {
      name              = "Analytical Platform Compute"
      description       = "Compute alerts for the Analytical Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_email_integration      = true
    },
    {
      name              = "Analytical Platform Storage"
      description       = "Compute alerts for the Analytical Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_email_integration      = true
    },
    {
      name              = "Data Platform"
      description       = "Generic alerts for the Data Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_email_integration      = true
      enable_cloudwatch_integration = true
    },
    {
      name              = "Data Platform Security"
      description       = "Security alerts for the Data Platform"
      escalation_policy = module.escalation_policies["Data Platform"].id
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
          type = "use_support_hours"
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
      enable_cloudwatch_integration    = true
      enable_cloudtrail_integration    = true
      enable_guardduty_integration     = true
      enable_security_hub_integration  = true
      enable_email_integration         = true
      enable_alert_manager_integration = true
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
  acknowledgement_timeout             = try(each.value.acknowledgement_timeout, "null")
  incident_urgency_rules              = try(each.value.incident_urgency_rules, [])
  auto_pause_notifications_parameters = try(each.value.auto_pause_notifications_parameters, [])
  support_hours                       = try(each.value.support_hours, [])
  enable_cloudwatch_integration       = try(each.value.enable_cloudwatch_integration, false)
  enable_cloudtrail_integration       = try(each.value.enable_cloudtrail_integration, false)
  enable_guardduty_integration        = try(each.value.enable_guardduty_integration, false)
  enable_health_dashboard_integration = try(each.value.enable_health_dashboard_integration, false)
  enable_security_hub_integration     = try(each.value.enable_security_hub_integration, false)
  enable_email_integration            = try(each.value.enable_email_integration, false)
  enable_airflow_integration          = try(each.value.enable_airflow_integration, false)
  enable_alert_manager_integration                = try(each.value.enable_alert_manager_integration, false)

  depends_on = [module.escalation_policies]
}
