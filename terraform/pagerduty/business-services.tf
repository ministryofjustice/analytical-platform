locals {
  business_services = [
    {
      name             = "Data Platform"
      description      = "Connecting the right people, systems, and data to improve justice outcomes"
      point_of_contact = "#ask-data-platform"
      team             = module.teams["Data Platform"].id
      supporting_services = [
        {
          name = "Data Platform High Priority"
          id   = module.technical_services["Data Platform High Priority"].id
          type = module.technical_services["Data Platform High Priority"].type
        },
        {
          name = "Cloud Platform"
          id   = data.pagerduty_business_service.cloud_platform.id
          type = data.pagerduty_business_service.cloud_platform.type
        },
        {
          name = "Modernisation Platform"
          id   = data.pagerduty_business_service.modernisation_platform.id
          type = data.pagerduty_business_service.modernisation_platform.type
        }
      ]
    }
  ]
}

module "business_services" {
  for_each = { for business_service in local.business_services : business_service.name => business_service }

  source              = "./modules/service/business"
  name                = each.key
  description         = each.value.description
  point_of_contact    = each.value.point_of_contact
  team                = each.value.team
  supporting_services = try(each.value.supporting_services, [])

  depends_on = [
    module.teams,
    module.technical_services
  ]
}
