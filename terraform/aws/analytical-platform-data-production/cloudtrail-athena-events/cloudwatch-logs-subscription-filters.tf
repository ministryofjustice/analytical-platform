module "cloudtrail_athena_events_subscription_filter" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-subscription-filter"
  version = "5.7.1"

  name            = "cloudtrail-athena-events"
  log_group_name  = "cloudtrail"
  filter_pattern  = "{ ($.eventName = \"StartQueryExecution\") }"
  destination_arn = module.cloudtrail_athena_event_processor_function.lambda_function_arn
}
