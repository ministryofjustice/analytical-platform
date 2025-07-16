resource "aws_cloudwatch_event_target" "jml_lambda_target" {
  rule      = aws_cloudwatch_event_rule.jml_lambda_trigger.name
  target_id = "SendToLambda"
  arn       = module.jml_report_lambda.lambda_function_arn
}
