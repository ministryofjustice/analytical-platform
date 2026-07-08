data "aws_iam_policy_document" "s3_topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "SNS:Publish"
    ]

    resources = [
      "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:s3-event-notification-topic"
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.bucket_event_rule.arn
      ]
    }
  }
}
