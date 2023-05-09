##################################################
# Data Catalogue Development
##################################################

module "ckan_route53_zone" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.10.2"

  zones = {
    "data-catalogue.dev.data-platform.service.justice.gov.uk" = {
      comment = "Data Catalogue Development"
      tags = {
        Name = "data-catalogue.dev.data-platform.service.justice.gov.uk"
      }
    }
  }
}
