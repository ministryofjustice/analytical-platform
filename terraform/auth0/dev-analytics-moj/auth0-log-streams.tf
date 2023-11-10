resource "auth0_log_stream" "aws_eventbridge_data_platform_apps_and_tools_development" {
  name   = "data-platform-apps-and-tools-development"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "335889174965"
    aws_region     = data.aws_region.current.name
  }
}
