resource "auth0_log_stream" "aws_eventbridge_alpha_analytics_moj" {
  name   = "alpha-analytics-moj"
  type   = "eventbridge"
  status = "active"

  sink {
    aws_account_id = "096705367497"
    aws_region     = data.aws_region.current.name
  }
}