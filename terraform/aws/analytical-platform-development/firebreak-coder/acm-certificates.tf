resource "aws_acm_certificate" "coder" {
  domain_name       = "coder.data-platform.moj.woffenden.dev"
  validation_method = "DNS"

  subject_alternative_names = ["*.coder.data-platform.moj.woffenden.dev"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "coder" {
  certificate_arn         = aws_acm_certificate.coder.arn
  validation_record_fqdns = [for record in aws_route53_record.coder_acm_validation : record.fqdn]
}
