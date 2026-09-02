# The following resource is belongs to Production environment
resource "aws_sns_topic" "splink_bucket_alerting_topic" {
  name              = "s3-event-notification-topic"
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
}
# The following resource is belongs to Test environment
resource "aws_sns_topic" "splink_bucket_alerting_topic_test" {
  name              = "s3-event-notification-topic-test"
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key_test.id
}


resource "aws_sns_topic_policy" "splink_bucket_alerting_topic_policy" {
  arn = aws_sns_topic.splink_bucket_alerting_topic.arn

  policy = data.aws_iam_policy_document.splink_bucket_alerting_topic_policy.json
}
