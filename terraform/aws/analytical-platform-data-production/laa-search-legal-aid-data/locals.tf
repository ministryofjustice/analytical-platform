locals {
  app = jsondecode(file("${path.module}/application_variables.json"))

  application_name            = local.app.application_name
  logging_bucket_name         = "moj-analytics-s3-logs-eu-west-2"
  splink_bucket_name          = local.app.splink_bucket_name
  splink_test_bucket_name     = local.app.splink_test_bucket_name
  splink_test_sns_topic_name  = "splink-s3-event-notification-topic-test"
  splink_test_event_rule_name = "splink-bucket-event-rule-test"
  tags                        = local.app.tags
  test_tags = merge(
    local.tags,
    {
      Environment = "test"
    }
  )
}
