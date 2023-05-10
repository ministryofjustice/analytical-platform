##################################################
# CKAN
##################################################

resource "aws_acm_certificate" "ckan" {
  domain_name       = "catalogue.${data.aws_route53_zone.data_platform_development.name}"
  validation_method = "DNS"
}
