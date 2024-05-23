module "route53_zones" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "2.11.1"

  zones = {
    "analytical-platform.service.justice.gov.uk" = {
      comment = "Managed by Terraform"
    }
  }
}

import {
  to = module.route53_zones.aws_route53_zone.this["analytical-platform.service.justice.gov.uk"]
  id = "Z2TGLAURT6S808"
}
