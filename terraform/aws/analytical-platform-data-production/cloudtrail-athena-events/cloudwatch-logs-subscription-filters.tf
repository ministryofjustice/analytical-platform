module "cloudtrail_athena_events_subscription_filter" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-subscription-filter"
  version = "5.6.1"

  name            = "cloudtrail-athena-events"
  log_group_name  = "cloudtrail"
  filter_pattern  = "{ ($.eventName = \"StartQueryExecution\") }"
  destination_arn = module.cloudtrail_athena_event_processor_function.lambda_function_arn
}
