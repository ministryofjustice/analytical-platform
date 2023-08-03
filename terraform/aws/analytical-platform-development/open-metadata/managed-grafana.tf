module "managed_grafana" {
  source  = "terraform-aws-modules/managed-service-grafana/aws"
  version = "2.0.0"

  name         = "open-metadata"
  license_type = "ENTERPRISE_FREE_TRIAL"

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
