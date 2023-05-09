##################################################
# Data Catalogue Development Zone
##################################################

module "ckan_route53_zone" {
  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.10.2"

  zones = {
    "${local.route53_zone_name}" = {
      comment = "Data Catalogue Development"
      tags = {
        Name = local.route53_zone_name
      }
    }
  }
}

##################################################
# Data Catalogue Development Records
##################################################

module "ckan_route53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.2"

  zone_name = local.route53_zone_name

  records = [
    {
      name    = ""
      type    = "A"
      ttl     = "300"
      records = data.dns_a_record_set.ckan_alb.addrs
    }
  ]
}
