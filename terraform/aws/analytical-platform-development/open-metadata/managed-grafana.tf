module "managed_grafana" {
  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "2.1.0"

  name = "open-metadata"

  /* We clickopsed the license, so we need to set this to false */
  # license_type = "ENTERPRISE_FREE_TRIAL"
  associate_license = false

  account_access_type       = "CURRENT_ACCOUNT"
  authentication_providers  = ["AWS_SSO"]
  permission_type           = "SERVICE_MANAGED"
  data_sources              = ["CLOUDWATCH", "PROMETHEUS"]
  notification_destinations = ["SNS"]

  role_associations = {
    "ADMIN" = {
      "group_ids" = ["86d22284-20f1-7083-0e1d-f7f69408e038"] # data-platform-core-infra
    }
  }
}

######### TEST

locals {
  expiration_days    = 30
  expiration_seconds = 60 * 60 * 24 * local.expiration_days
}

resource "time_rotating" "rotate" {
  rotation_days = local.expiration_days
}

resource "time_static" "rotate" {
  rfc3339 = time_rotating.rotate.rfc3339
}

resource "aws_grafana_workspace_api_key" "automation_key" {
  workspace_id = module.managed_grafana.workspace_id

  key_name        = "automation"
  key_role        = "ADMIN"
  seconds_to_live = local.expiration_seconds

  lifecycle {
    replace_triggered_by = [
      time_static.rotate
    ]
  }
}

resource "grafana_team" "data_platform" {
  name = "data-platform"
}
