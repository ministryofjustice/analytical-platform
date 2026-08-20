locals {
  app           = jsondecode(file("${path.module}/application_variables.json"))
  kms_key_users = jsondecode(file("${path.module}/kms_key_users.json"))

  splink_s3_key_user_arns = [
    for role in local.kms_key_users.splink_s3_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  splink_s3_test_key_user_arns = [
    for role in local.kms_key_users.splink_s3_test_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  application_name                 = local.app.application_name
  splink_search_input_bucket_name  = local.app.splink_search_input_bucket_name
  splink_search_output_bucket_name = local.app.splink_search_output_bucket_name
  splink_source_input_bucket_name  = local.app.splink_source_input_bucket_name
  splink_source_output_bucket_name = local.app.splink_source_output_bucket_name
  splink_audit_bucket_name         = local.app.splink_audit_bucket_name
  logging_bucket_name              = local.app.logging_bucket_name
  splink_bucket_name               = local.app.splink_bucket_name
  splink_test_bucket_name          = local.app.splink_test_bucket_name
  splink_test_sns_topic_name       = "splink-s3-event-notification-topic-test"
  splink_test_event_rule_name      = "splink-bucket-event-rule-test"
  tags                             = local.app.tags
  test_tags = merge(
    local.tags,
    {
      Environment = "test"
    }
  )
}
