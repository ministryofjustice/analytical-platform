resource "aws_cloudwatch_event_target" "auth0" {
  target_id      = "Idebe8360d-2f5a-4136-9bbe-977efb26a16a"
  event_bus_name = data.aws_cloudwatch_event_bus.auth0.name
  rule           = aws_cloudwatch_event_rule.auth0_cloudwatch.name
  arn            = aws_cloudwatch_log_group.auth0.arn
}
