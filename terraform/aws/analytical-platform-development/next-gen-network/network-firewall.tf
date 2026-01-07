resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.strict.arn
  vpc_id              = aws_vpc.main.id

  dynamic "subnet_mapping" {
    for_each = {
      "firewall-a" = aws_subnet.main["firewall-a"]
      "firewall-b" = aws_subnet.main["firewall-b"]
      "firewall-c" = aws_subnet.main["firewall-c"]
    }

    content {
      subnet_id = subnet_mapping.value.id
    }
  }
}

resource "aws_networkfirewall_logging_configuration" "cloudwatch" {
  firewall_arn = aws_networkfirewall_firewall.main.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = module.network_firewall_flow_logs_log_group.cloudwatch_log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
    log_destination_config {
      log_destination = {
        logGroup = module.network_firewall_alert_logs_log_group.cloudwatch_log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "strict" {
  name = "strict"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    # Recommended for STRICT_ORDER so TCP can establish and app-layer rules can match
    stateful_default_actions = [
      "aws:drop_established",
      "aws:alert_established",
    ]

    stateful_rule_group_reference {
      priority     = 1
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/AttackInfrastructureStrictOrder"
    }

    stateful_rule_group_reference {
      priority     = 2
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/BotNetCommandAndControlDomainsStrictOrder"
    }

    stateful_rule_group_reference {
      priority     = 3
      resource_arn = "arn:aws:network-firewall:eu-west-2:aws-managed:stateful-rulegroup/MalwareDomainsStrictOrder"
    }

    # 1) IP/port allowlist (SSH)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.strict.arn
      priority     = 10
    }

    # 2) FQDN allowlist (HTTP host + TLS SNI)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.strict_fqdn.arn
      priority     = 20
    }
  }
}

locals {
  // To debug:
  // templatefile("src/ip.rules.tftpl", { rules = local.ip_rules })
  // templatefile("src/fqdn.rules.tftpl", { rules = local.fqdn_rules })

  ip_rules = {
    home_net_whoami_filippo_io_ssh = {
      sid              = 1
      revision         = 1
      action           = "pass"
      protocol         = "tcp"
      source_ip        = "$HOME_NET"
      source_port      = "any"
      direction        = "->"
      destination_ip   = "213.188.195.127"
      destination_port = "22"
      description      = "Allow SSH to whoami.filippo.io"
    }
  }
  fqdn_rules = {
    home_net_api_github_com_https = {
      sid              = 1
      revision         = 1
      action           = "pass"
      protocol         = "tcp"
      source_ip        = "$HOME_NET"
      source_port      = "any"
      direction        = "->"
      destination_ip   = "any"
      destination_port = "443"
      type             = "tls.sni" // tls.sni or http.host
      content          = "api.github.com"
      description      = "Allow HTTPS to api.github.com"
    }
    home_net_google_com_https = {
      sid              = 2
      revision         = 1
      action           = "pass"
      protocol         = "tcp"
      source_ip        = "$HOME_NET"
      source_port      = "any"
      direction        = "->"
      destination_ip   = "any"
      destination_port = "443"
      type             = "tls.sni" // tls.sni or http.host
      content          = "google.com"
      description      = "Allow HTTPS to google.com"
    }
    home_net_www_google_com_https = {
      sid              = 2
      revision         = 1
      action           = "pass"
      protocol         = "tcp"
      source_ip        = "$HOME_NET"
      source_port      = "any"
      direction        = "->"
      destination_ip   = "any"
      destination_port = "443"
      type             = "tls.sni" // tls.sni or http.host
      content          = "www.google.com"
      description      = "Allow HTTPS to www.google.com"
    }
  }
}

resource "aws_networkfirewall_rule_group" "strict" {
  name     = "strict"
  type     = "STATEFUL"
  capacity = 10000

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [aws_vpc.main.cidr_block]
        }
      }
    }

    rules_source {
      rules_string = templatefile("src/ip.rules.tftpl", { rules = local.ip_rules })
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}

resource "aws_networkfirewall_rule_group" "strict_fqdn" {
  name     = "strict-fqdn"
  type     = "STATEFUL"
  capacity = 3000

  rule_group {
    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = [aws_vpc.main.cidr_block]
        }
      }
    }

    rules_source {
      rules_string = templatefile("src/fqdn.rules.tftpl", { rules = local.fqdn_rules })
    }

    stateful_rule_options {
      rule_order = "STRICT_ORDER"
    }
  }
}
