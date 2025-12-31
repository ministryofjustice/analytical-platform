resource "aws_networkfirewall_firewall" "main" {
  name                = "${local.application_name}-${local.environment}"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.stateful.arn
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

#### NEW BASED ON (livedatainlinefwpolicy4LU)

resource "aws_networkfirewall_firewall_policy" "stateful" {
  name = "stateful"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:drop"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.stateful.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.statful_fqdn.arn
    }

    stateful_engine_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
  }
}

resource "aws_networkfirewall_rule_group" "stateful" {
  name     = "stateful"
  type     = "STATEFUL"
  capacity = 10000

  rule_group {
    rules_source {
      stateful_rule {
        action = "PASS"
        header {
          destination      = "213.188.195.127/32" # whoami.filippo.io
          destination_port = "22"
          direction        = "ANY"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1"]
        }
      }
    }

    stateful_rule_options {
      rule_order = "DEFAULT_ACTION_ORDER"
    }
  }
}

resource "aws_networkfirewall_rule_group" "statful_fqdn" {
  name     = "statful-fqdn"
  type     = "STATEFUL"
  capacity = 3000

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

          # Testing connectivity
          ".google.com",

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

/*
TODO:
 - Revisit this configuration
   - statful_fqdn works
   - stateful sort of works, it allows SSH to whoami.filippo.io BUT ALSO github.com, which is not intended.
References:
 - https://github.com/ministryofjustice/modernisation-platform/blob/main/terraform/environments/core-network-services/firewall.tf
 - https://github.com/ministryofjustice/modernisation-platform/tree/main/terraform/modules/firewall-policy
 - https://github.com/ministryofjustice/modernisation-platform/tree/main/terraform/environments/core-network-services/firewall-rules
*/
