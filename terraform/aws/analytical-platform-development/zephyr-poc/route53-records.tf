module "route53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "4.1.0"

  zone_id = data.aws_route53_zone.dev_analytical_platform_service_justice_gov_uk.zone_id

  records = [
    {
      name    = "zephyr"
      type    = "CNAME"
      ttl     = 300
      records = [module.alb.dns_name]
    }
  ]
}
