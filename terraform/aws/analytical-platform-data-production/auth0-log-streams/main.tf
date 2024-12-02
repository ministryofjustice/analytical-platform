locals {
  auth0_log_streams = {
    "alpha-analytics-moj" = {
      event_source_name = "aws.partner/auth0.com/alpha-analytics-moj-8b47abb4-3107-4f42-9a8f-f13126a80493/auth0.logs"
    }
    "dev-analytics-moj" = {
      event_source_name = "aws.partner/auth0.com/dev-analytics-moj-874bd718-90b5-4cab-9aee-0ccb097dd112/auth0.logs"
    }
  }
}

module "auth0_log_streams" {
  source = "./modules/auth0-log-streams"

  for_each = local.auth0_log_streams

  name              = each.key
  event_source_name = each.value.event_source_name
}
