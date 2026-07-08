resource "aws_sns_topic" "s3_topic" {
  name              = "s3-event-notification-topic"
  kms_master_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
}

resource "aws_sns_topic_policy" "s3_topic_policy" {
  arn = aws_sns_topic.s3_topic.arn

  policy = data.aws_iam_policy_document.s3_topic_policy.json
}
