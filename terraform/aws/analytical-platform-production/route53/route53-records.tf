module "route53_records" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "5.0.0"

  zone_id = module.route53_zones.route53_zone_zone_id["analytical-platform.service.justice.gov.uk"]

  records = [
    {
      name = "docs"
      type = "CNAME"
      ttl  = 300
      records = [
        "ministryofjustice.github.io."
      ]
    },
    {
      name = "compute.development"
      type = "NS"
      ttl  = 300
      records = [
        "ns-676.awsdns-20.net.",
        "ns-492.awsdns-61.com.",
        "ns-1979.awsdns-55.co.uk.",
        "ns-1364.awsdns-42.org."
      ]
    },
    {
      name = "compute.test"
      type = "NS"
      ttl  = 300
      records = [
        "ns-329.awsdns-41.com.",
        "ns-736.awsdns-28.net.",
        "ns-1094.awsdns-08.org.",
        "ns-1604.awsdns-08.co.uk."
      ]
    },
    {
      name = "compute"
      type = "NS"
      ttl  = 300
      records = [
        "ns-1143.awsdns-14.org.",
        "ns-121.awsdns-15.com.",
        "ns-633.awsdns-15.net.",
        "ns-1852.awsdns-39.co.uk."
      ]
    },
    {
      name = "development"
      type = "CNAME"
      ttl  = 300
      records = [
        "ingress.compute.development.analytical-platform.service.justice.gov.uk."
      ]
    },
    {
      name = "dashboards.development"
      type = "CNAME"
      ttl  = 300
      records = [
        "ingress.compute.development.analytical-platform.service.justice.gov.uk."
      ]
    },
    {
      name = "dashboards"
      type = "CNAME"
      ttl  = 300
      records = [
        "ingress.compute.analytical-platform.service.justice.gov.uk."
      ]
    },
    {
      name = "test"
      type = "CNAME"
      ttl  = 300
      records = [
        "ingress.compute.test.analytical-platform.service.justice.gov.uk."
      ]
    },
    {
      name    = ""
      type    = "A"
      ttl     = 300
      records = tolist(data.dns_a_record_set.apc_ingress_prod.addrs)
    },
    {
      name = "observability"
      type = "NS"
      ttl  = 300
      records = [
        "ns-1326.awsdns-37.org.",
        "ns-146.awsdns-18.com.",
        "ns-1010.awsdns-62.net.",
        "ns-1929.awsdns-49.co.uk."
      ]
    },
    {
      name    = "next"
      type    = "CNAME"
      ttl     = 300
      records = ["ingress.compute.development.analytical-platform.service.justice.gov.uk."]
    },
  ]
}
