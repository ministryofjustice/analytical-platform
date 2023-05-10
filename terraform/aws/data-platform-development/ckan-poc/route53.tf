##################################################
# CKAN
##################################################

resource "aws_route53_record" "ckan" {
  zone_id = data.aws_route53_zone.data_platform_development.zone_id
  name    = "catalogue.${data.aws_route53_zone.data_platform_development.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [module.ckan_alb.lb_dns_name]
}

##################################################
# CKAN ACM Validation
##################################################

resource "aws_route53_record" "ckan_acm" {
  for_each = {
    for dvo in aws_acm_certificate.ckan.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.data_platform_development.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
  allow_overwrite = true
}
