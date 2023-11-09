resource "aws_cloudwatch_event_target" "auth0" {
  target_id      = "28uj7iu-e907f95-mu9x0esbu-76cl9jjp9" // This is because I ClickOps'd the target in the UI
  event_bus_name = data.aws_cloudwatch_event_bus.auth0.name
  rule           = aws_cloudwatch_event_rule.auth0_cloudwatch.name
  arn            = aws_cloudwatch_log_group.auth0.arn
}