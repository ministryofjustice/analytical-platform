resource "aws_acm_certificate" "open_metadata" {
  domain_name       = "open-metadata.data-platform.moj.woffenden.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "datahub" {
  domain_name       = "datahub.data-platform.moj.woffenden.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
