#This file contains the Key User ARNs, Buckets name variables for Prod and test and other logging, SNS variables
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

  # The below ARNs are used for Production Buckets
  # The following variables belongs to laa-splink-source-file-input
  splink_s3_source_input_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_input_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_input_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_input_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following variables belongs to laa-splink-source-file-output
  splink_s3_source_output_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_output_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_output_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_output_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following variables belongs to laa-splink-search-input
  splink_s3_search_input_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_input_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_search_input_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_input_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following variables belongs to laa-splink-search-output
  splink_s3_search_output_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_output_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_search_output_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_output_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following variables belongs to laa-search-audit
  splink_s3_audit_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_audit_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following variables belongs to laa-splink-source-zip
  splink_s3_source_zip_write_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_zip_write_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_zip_read_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_zip_read_bucket.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The below ARNs are used for Test Buckets
  # The below Key users belongs to source test bucket
  splink_s3_source_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The below Key users belongs to source input test bucket
  splink_s3_source_input_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_input_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_input_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_input_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following users belongs to Search Input Test bucket
  splink_s3_search_input_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_input_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_search_input_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_input_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following users belongs to Search Output Test bucket
  splink_s3_search_output_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_output_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_search_output_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_search_output_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following users belongs to Source Output Test bucket
  splink_s3_source_output_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_output_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_output_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_output_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following users belongs to Audit Test bucket
  splink_s3_audit_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_audit_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_audit_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]

  # The following users belongs to Source Zip Test Bucket
  splink_s3_source_zip_write_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_zip_write_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]
  splink_s3_source_zip_read_test_bucket_key_user_arns = [
    for role in local.kms_key_users.splink_s3_source_zip_read_bucket_test.key_users :
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${role}"
  ]


  #Production buckets variables
  application_name                 = local.app.application_name
  splink_source_bucket_name        = local.app.splink_source_bucket_name
  splink_search_input_bucket_name  = local.app.splink_search_input_bucket_name
  splink_search_output_bucket_name = local.app.splink_search_output_bucket_name
  splink_source_input_bucket_name  = local.app.splink_source_input_bucket_name
  splink_source_output_bucket_name = local.app.splink_source_output_bucket_name
  splink_audit_bucket_name         = local.app.splink_audit_bucket_name
  splink_source_zip_bucket_name    = local.app.splink_source_zip_bucket_name
  #Test buckets variables
  splink_source_bucket_test_name        = local.app.splink_source_test_bucket_name
  splink_search_input_bucket_test_name  = local.app.splink_search_input_test_bucket_name
  splink_search_output_bucket_test_name = local.app.splink_search_output_test_bucket_name
  splink_source_input_bucket_test_name  = local.app.splink_source_input_test_bucket_name
  splink_source_output_bucket_test_name = local.app.splink_source_output_test_bucket_name
  splink_source_zip_bucket_test_name    = local.app.splink_source_zip_test_bucket_name
  splink_audit_bucket_test_name         = local.app.splink_audit_test_bucket_name
  #Logging, SNS, Bucket event rule variables
  # S3 access logging requires the target bucket to be in the same region as the
  # source bucket. `moj-analytics-s3-logs` (no suffix) is the eu-west-1 logging
  # bucket; `-eu-west-2` is a separate, region-specific bucket provisioned for
  # eu-west-2 workspaces like this one (all buckets here are eu-west-2, see
  # terraform.tf), hence the region suffix in the name.
  logging_bucket_name         = local.app.logging_bucket_name
  splink_bucket_name          = local.app.splink_bucket_name
  splink_test_bucket_name     = local.app.splink_test_bucket_name
  splink_test_sns_topic_name  = "splink-s3-event-notification-topic-test"
  splink_test_event_rule_name = "splink-bucket-event-rule-test"
  tags                        = local.app.tags
  test_tags = merge(local.tags, {
    Environment = "test"
  })
}
