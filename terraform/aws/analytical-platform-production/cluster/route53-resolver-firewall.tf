resource "aws_secretsmanager_secret" "route53_resolver_firewall_blocked_domains" {
  #checkov:skip=CKV2_AWS_57:Automatic rotation is not required for this secret
  #checkov:skip=CKV_AWS_149:CMK encryption is not required for this secret
  name        = "production/route53-resolver-firewall-blocked-domains"
  description = "Blocked domains for the Route53 resolver firewall"
  kms_key_id  = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "route53_resolver_firewall_blocked_domains" {
  secret_id = aws_secretsmanager_secret.route53_resolver_firewall_blocked_domains.id

  lifecycle {
    # This secret is expected to be updated outside Terraform after bootstrap.
    ignore_changes = all
  }

  secret_string = "CHANGE_ME"
}

locals {
  route53_resolver_firewall_blocked_domains = distinct(compact([
    for domain in split(",", try(data.aws_secretsmanager_secret_version.route53_resolver_firewall_blocked_domains_current.secret_string, "")) :
    trimspace(domain)
  ]))
}

resource "aws_route53_resolver_firewall_domain_list" "blocked_domains" {
  name    = "production-route53-resolver-firewall-blocked-domains"
  domains = local.route53_resolver_firewall_blocked_domains
}

resource "aws_route53_resolver_firewall_rule_group" "blocked_domains" {
  name = "production-route53-resolver-firewall"
}

resource "aws_route53_resolver_firewall_rule" "blocked_domains" {
  action                  = "BLOCK"
  block_response          = "NXDOMAIN"
  firewall_domain_list_id = aws_route53_resolver_firewall_domain_list.blocked_domains.id
  firewall_rule_group_id  = aws_route53_resolver_firewall_rule_group.blocked_domains.id
  name                    = "production-blocked-domains"
  priority                = 100
}

resource "aws_route53_resolver_firewall_rule_group_association" "vpc" {
  firewall_rule_group_id = aws_route53_resolver_firewall_rule_group.blocked_domains.id
  name                   = "production-route53-resolver-firewall"
  priority               = 101
  vpc_id                 = module.vpc.vpc_id

  depends_on = [aws_route53_resolver_query_log_config_association.core_logging_s3]
}
