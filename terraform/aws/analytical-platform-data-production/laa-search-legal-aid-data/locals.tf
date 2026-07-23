locals {
  app = jsondecode(file("${path.module}/application_variables.json"))

  application_name    = local.app.application_name
  logging_bucket_name = local.app.logging_bucket_name
  splink_bucket_name  = local.app.splink_bucket_name
  tags                = local.app.tags
}
