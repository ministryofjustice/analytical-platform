module "certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  zone_id     = data.aws_route53_zone.dev_analytical_platform_service_justice_gov_uk.zone_id
  domain_name = local.mwaa_webserver_base_url

  validation_method = "DNS"
}
