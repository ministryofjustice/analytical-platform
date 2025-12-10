resource "aws_networkfirewall_rule_group" "allow_domains" {
  name     = "allow-approved-domains"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST", "TLS_SNI"]
        targets = [
          # Government domains
          ".gov.uk",
          ".justice.gov.uk",

          # Development tools
          ".github.com",
          ".githubusercontent.com",
          ".gitlab.com",

          # Package managers
          ".pypi.org",
          ".pythonhosted.org",
          ".npmjs.org",
          ".npmjs.com",
          ".cran.r-project.org",

          # AWS services
          ".amazonaws.com",
          ".aws.amazon.com",
        ]
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "allow_non_http_services" {
  name     = "allow-non-http-services"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      # Example: Allow SSH to specific internal server
      stateful_rule {
        action = "PASS"
        header {
          destination      = "10.0.1.100/32"
          destination_port = "22"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }

      # Example: Allow PostgreSQL to RDS endpoint
      stateful_rule {
        action = "PASS"
        header {
          destination      = "10.0.2.0/24"
          destination_port = "5432"
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["2"]
        }
      }

      # Example: Allow NTP (non-HTTP protocol)
      stateful_rule {
        action = "PASS"
        header {
          destination      = "ANY"
          destination_port = "123"
          direction        = "FORWARD"
          protocol         = "UDP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["3"]
        }
      }
    }

    stateful_rule_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
  }
}

resource "aws_networkfirewall_firewall_policy" "main" {
  name = "main"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    # FQDN-based filtering for HTTP/HTTPS traffic
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_domains.arn
    }

    # IP/Port-based filtering for non-HTTP protocols (SSH, databases, etc.)
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allow_non_http_services.arn
    }

    # Start permissive - drop_strict can be added later once stable
    # stateful_default_actions = ["aws:drop_strict"]

    stateful_engine_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
  }
}

resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.main.arn
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
