resource "aws_acm_certificate" "open_metadata" {
  domain_name       = "open-metadata.data-platform.moj.woffenden.dev"
  validation_method = "DNS"
}
