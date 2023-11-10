resource "auth0_log_stream" "aws_eventbridge_data_platform_apps_and_tools_production" {
  name   = "data-platform-apps-and-tools-production"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "096705367497"
    aws_region     = "eu-west-2"
  }
}
