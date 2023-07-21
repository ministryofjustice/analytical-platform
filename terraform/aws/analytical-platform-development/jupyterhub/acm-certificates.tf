resource "aws_acm_certificate" "jupyterhub" {
  domain_name       = "hub.data-platform.moj.woffenden.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "jupyterhub" {
  certificate_arn         = aws_acm_certificate.jupyterhub.arn
  validation_record_fqdns = [for record in aws_route53_record.jupyterhub_acm_validation : record.fqdn]
}
