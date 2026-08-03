locals {
  app = jsondecode(file("${path.module}/application_variables.json"))

  application_name    = local.app.application_name
  logging_bucket_name = "moj-analytics-s3-logs-eu-west-2"
  splink_bucket_name  = local.app.splink_bucket_name
  tags                = local.app.tags
}
