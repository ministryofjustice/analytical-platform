resource "aws_route53_record" "transfer_server" {
  provider = aws.analytical-platform-production

  zone_id = data.aws_route53_zone.analytical_platform_service_justice_gov_uk.zone_id
  name    = "sftp.development.ingestion.analytical-platform.service.justice.gov.uk."
  type    = "CNAME"
  ttl     = 300
  records = [aws_transfer_server.this.endpoint]
}
