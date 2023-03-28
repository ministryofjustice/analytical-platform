resource "pagerduty_business_service" "this" {
  name             = var.name
  description      = var.description
  point_of_contact = var.point_of_contact
  team             = var.team
}

resource "pagerduty_service_dependency" "supporting_services" {
  for_each = { for supporting_service in var.supporting_services : supporting_service.name => supporting_service }

  dependency {
    dependent_service {
      id   = pagerduty_business_service.this.id
      type = pagerduty_business_service.this.type
    }
    supporting_service {
      id   = each.value.id
      type = each.value.type
    }
  }
}
