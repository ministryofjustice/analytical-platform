locals {
  technical_services = [
    {
      name              = "Data Platform High Priority"
      escalation_policy = module.escalation_policies["Data Platform"].id
    },
    {
      name              = "Data Platform Low Priority"
      escalation_policy = module.escalation_policies["Data Platform"].id
    }
  ]
}

module "technical_services" {
  for_each = { for technical_service in local.technical_services : technical_service.name => technical_service }

  source            = "./modules/service/technical"
  name              = each.key
  escalation_policy = each.value.escalation_policy

  depends_on = [module.escalation_policies]
}
