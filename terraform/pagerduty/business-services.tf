locals {
  business_services = [
    {
      name             = "Analytical Platform"
      description      = "Ministry of Justice's data analysis platform."
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
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
