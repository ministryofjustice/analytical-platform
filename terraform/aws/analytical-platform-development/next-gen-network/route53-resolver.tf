resource "aws_route53_resolver_firewall_config" "main" {
  resource_id        = aws_vpc.main.id
  firewall_fail_open = "ENABLED"
}
