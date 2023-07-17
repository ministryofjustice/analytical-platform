resource "aws_route53_zone" "data_platform_moj_woffenden_dev" {
  #checkov:skip=CKV2_AWS_39:This is not production infrastructure
  #checkov:skip=CKV2_AWS_38:This is not production infrastructure

  name = "data-platform.moj.woffenden.dev"
}

resource "aws_route53_record" "open_metadata" {
  for_each = {
    for dvo in aws_acm_certificate.open_metadata.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.data_platform_moj_woffenden_dev.zone_id
}

resource "aws_acm_certificate_validation" "open_metadata" {
  certificate_arn         = aws_acm_certificate.open_metadata.arn
  validation_record_fqdns = [for record in aws_route53_record.open_metadata : record.fqdn]
}

resource "aws_route53_record" "datahub" {
  for_each = {
    for dvo in aws_acm_certificate.datahub.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.data_platform_moj_woffenden_dev.zone_id
}

resource "aws_acm_certificate_validation" "datahub" {
  certificate_arn         = aws_acm_certificate.datahub.arn
  validation_record_fqdns = [for record in aws_route53_record.datahub : record.fqdn]
}
