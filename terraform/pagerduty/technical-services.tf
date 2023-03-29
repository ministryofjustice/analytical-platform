locals {
  technical_services = [
    {
      name              = "Analytical Platform High Priority"
      description       = "High priority incidents for the Analytical Platform team"
      escalation_policy = module.escalation_policies["Analytical Platform"].id
    },
    {
      name              = "Analytical Platform Low Priority"
      description       = "Low priority incidents for the Analytical Platform team"
      escalation_policy = module.escalation_policies["Analytical Platform"].id
    },
    {
      name              = "Data Platform High Priority"
      description       = "High priority incidents for the Data Platform team"
      escalation_policy = module.escalation_policies["Data Platform"].id
    },
    {
      name              = "Data Platform Low Priority"
      description       = "Low priority incidents for the Data Platform team"
      escalation_policy = module.escalation_policies["Data Platform"].id
    }
  ]
}

module "technical_services" {
  for_each = { for technical_service in local.technical_services : technical_service.name => technical_service }

  source            = "./modules/service/technical"
  name              = each.key
  description       = each.value.description
  escalation_policy = each.value.escalation_policy
  alert_creation    = try(each.value.alert_creation, "create_alerts_and_incidents")

  depends_on = [module.escalation_policies]
}
