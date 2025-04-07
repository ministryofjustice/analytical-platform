module "route53_zones" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV2_AWS_38:Will address in the future, this is just an import of the zone
  #checkov:skip=CKV2_AWS_39:Will address in the future, this is just an import of the zone

  source  = "terraform-aws-modules/route53/aws//modules/zones"
  version = "5.0.0"

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
