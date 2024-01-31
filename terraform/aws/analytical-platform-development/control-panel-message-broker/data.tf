data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid = "InboundManagementSqsMessages"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]

    principals {
      type        = "AWS"
      identifiers = [local.control_panel_api_arn]
    }
  }
}
