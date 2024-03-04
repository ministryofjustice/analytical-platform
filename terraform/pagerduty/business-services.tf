locals {
  business_services = [
    {
      name             = "Analytical Platform Compute"
      description      = "Analytical Platform Compute"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Compute"
          id   = module.technical_services["Analytical Platform Compute"].id
          type = "service"
        }
      ]
    },
    {
      name             = "Analytical Platform Identity"
      description      = "Analytical Platform Identity"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Identity"
          id   = module.technical_services["Analytical Platform Identity"].id
          type = "service"
        }
      ]
    },
    {
      name             = "Analytical Platform Ingestion"
      description      = "Analytical Platform Ingestion"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Ingestion"
          id   = module.technical_services["Analytical Platform Ingestion"].id
          type = "service"
        }
      ]
    },
    {
      name             = "Analytical Platform Networking"
      description      = "Analytical Platform Networking"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Networking"
          id   = module.technical_services["Analytical Platform Networking"].id
          type = "service"
        }
      ]
    },
    {
      name             = "Analytical Platform Security"
      description      = "Analytical Platform Security"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Security"
          id   = module.technical_services["Analytical Platform Security"].id
          type = "service"
        }
      ]
    },
    {
      name             = "Analytical Platform Storage"
      description      = "Analytical Platform Storage"
      point_of_contact = "#analytical-platform"
      team             = module.teams["Analytical Platform"].id
      supporting_services = [
        {
          name = "Analytical Platform Storage"
          id   = module.technical_services["Analytical Platform Storage"].id
          type = "service"
        }
      ]
    },
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
