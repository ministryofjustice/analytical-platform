locals {
  name_machine_friendly       = lower(replace(var.name, " ", "-"))
  secretsmanager_prefix       = "pagerduty/${local.name_machine_friendly}/integration-keys"
  pagerduty_integration_email = "${local.name_machine_friendly}@moj-digital-tools.pagerduty.com"
}

resource "pagerduty_service" "this" {
  name                    = var.name
  description             = var.description
  escalation_policy       = var.escalation_policy
  alert_creation          = var.alert_creation
  auto_resolve_timeout    = var.auto_resolve_timeout
  acknowledgement_timeout = var.acknowledgement_timeout

  dynamic "auto_pause_notifications_parameters" {
    for_each = var.auto_pause_notifications_parameters

    content {
      enabled = auto_pause_notifications_parameters.value.enabled
      timeout = auto_pause_notifications_parameters.value.timeout
    }
  }

  dynamic "support_hours" {
    for_each = var.support_hours
    content {
      type         = support_hours.value["type"]
      start_time   = support_hours.value["start_time"]
      end_time     = support_hours.value["end_time"]
      time_zone    = support_hours.value["time_zone"]
      days_of_week = support_hours.value["days_of_week"]
    }
  }

  dynamic "incident_urgency_rule" {
    for_each = { for incident_urgency_rule in var.incident_urgency_rules : incident_urgency_rule.type => incident_urgency_rule }

    content {
      type    = incident_urgency_rule.value.type
      urgency = incident_urgency_rule.value.urgency

      dynamic "during_support_hours" {
        for_each = incident_urgency_rule.value.during_support_hours

        content {
          type    = during_support_hours.value.type
          urgency = during_support_hours.value.urgency
        }
      }

      dynamic "outside_support_hours" {
        for_each = incident_urgency_rule.value.outside_support_hours

        content {
          type    = outside_support_hours.value.type
          urgency = outside_support_hours.value.urgency
        }
      }
    }
  }
}

##################################################
# CloudWatch Integration
##################################################

data "pagerduty_vendor" "cloudwatch" {
  name = "Amazon CloudWatch"
}

resource "pagerduty_service_integration" "cloudwatch" {
  count = var.enable_cloudwatch_integration ? 1 : 0

  name    = data.pagerduty_vendor.cloudwatch.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.cloudwatch.id
}

resource "aws_secretsmanager_secret" "pagerduty_cloudwatch_integration_key" {
  count = var.enable_cloudwatch_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/cloudwatch"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_cloudwatch_integration_key" {
  count = var.enable_cloudwatch_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_cloudwatch_integration_key[0].id
  secret_string = pagerduty_service_integration.cloudwatch[0].integration_key
}

##################################################
# CloudTrail Integration
##################################################

data "pagerduty_vendor" "cloudtrail" {
  name = "AWS CloudTrail"
}

resource "pagerduty_service_integration" "cloudtrail" {
  count = var.enable_cloudtrail_integration ? 1 : 0

  name    = data.pagerduty_vendor.cloudtrail.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.cloudtrail.id
}

resource "aws_secretsmanager_secret" "pagerduty_cloudtrail_integration_key" {
  count = var.enable_cloudtrail_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/cloudtrail"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_cloudtrail_integration_key" {
  count = var.enable_cloudtrail_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_cloudtrail_integration_key[0].id
  secret_string = pagerduty_service_integration.cloudtrail[0].integration_key
}

##################################################
# GuardDuty Integration
##################################################

data "pagerduty_vendor" "guardduty" {
  name = "Amazon GuardDuty"
}

resource "pagerduty_service_integration" "guardduty" {
  count = var.enable_guardduty_integration ? 1 : 0

  name    = data.pagerduty_vendor.guardduty.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.guardduty.id
}

resource "aws_secretsmanager_secret" "pagerduty_guardduty_integration_key" {
  count = var.enable_guardduty_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/guardduty"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_guardduty_integration_key" {
  count = var.enable_guardduty_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_guardduty_integration_key[0].id
  secret_string = pagerduty_service_integration.guardduty[0].integration_key
}

##################################################
# Health Dashboard Integration
##################################################

data "pagerduty_vendor" "health_dashboard" {
  name = "AWS Health Dashboard"
}

resource "pagerduty_service_integration" "health_dashboard" {
  count = var.enable_health_dashboard_integration ? 1 : 0

  name    = data.pagerduty_vendor.health_dashboard.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.health_dashboard.id
}

resource "aws_secretsmanager_secret" "pagerduty_health_dashboard_integration_key" {
  count = var.enable_health_dashboard_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/health-dashboard"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_health_dashboard_integration_key" {
  count = var.enable_health_dashboard_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_health_dashboard_integration_key[0].id
  secret_string = pagerduty_service_integration.health_dashboard[0].integration_key
}

##################################################
# Security Hub Integration
##################################################

data "pagerduty_vendor" "security_hub" {
  name = "AWS Security Hub"
}

resource "pagerduty_service_integration" "security_hub" {
  count = var.enable_security_hub_integration ? 1 : 0

  name    = data.pagerduty_vendor.security_hub.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.security_hub.id
}

resource "aws_secretsmanager_secret" "pagerduty_security_hub_integration_key" {
  count = var.enable_security_hub_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/security-hub"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_security_hub_integration_key" {
  count = var.enable_security_hub_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_security_hub_integration_key[0].id
  secret_string = pagerduty_service_integration.security_hub[0].integration_key
}

##################################################
# Email Integration
##################################################

data "pagerduty_vendor" "email" {
  name = "Email"
}

resource "pagerduty_service_integration" "email" {
  count = var.enable_email_integration ? 1 : 0

  name              = data.pagerduty_vendor.email.name
  service           = pagerduty_service.this.id
  vendor            = data.pagerduty_vendor.email.id
  integration_email = local.pagerduty_integration_email
}

resource "aws_secretsmanager_secret" "pagerduty_email_integration_key" {
  count = var.enable_email_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/email"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_email_integration_key" {
  count = var.enable_email_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_email_integration_key[0].id
  secret_string = local.pagerduty_integration_email
}

##################################################
# Airflow Integration
##################################################

data "pagerduty_vendor" "airflow" {
  name = "Airflow Integration"
}

resource "pagerduty_service_integration" "airflow" {
  count = var.enable_airflow_integration ? 1 : 0

  name    = data.pagerduty_vendor.airflow.name
  service = pagerduty_service.this.id
  vendor  = data.pagerduty_vendor.airflow.id
}

resource "aws_secretsmanager_secret" "pagerduty_airflow_integration_key" {
  count = var.enable_airflow_integration ? 1 : 0

  name       = "${local.secretsmanager_prefix}/airflow"
  kms_key_id = "alias/aws/secretsmanager"
}

resource "aws_secretsmanager_secret_version" "pagerduty_airflow_integration_key" {
  count = var.enable_airflow_integration ? 1 : 0

  secret_id     = aws_secretsmanager_secret.pagerduty_airflow_integration_key[0].id
  secret_string = pagerduty_service_integration.airflow[0].integration_key
}
