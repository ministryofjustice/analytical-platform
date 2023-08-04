data "aws_iam_policy_document" "source" {
  statement {
    sid = "InboundManagementSqsMessages"

    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = [local.control_panel_api_arn]
    }
  }
}

data "aws_iam_policy_document" "sqs_iam_policy_document" {
  source_json = data.aws_iam_policy_document.source.json

  statement {
    resources = [aws_sqs_queue.iam_queue.arn]
  }
}

data "aws_iam_policy_document" "sqs_s3_policy_document" {
  source_json = data.aws_iam_policy_document.source.json

  statement {
    resources = [aws_sqs_queue.s3_queue.arn]
  }
}

data "aws_iam_policy_document" "sqs_auth_policy_document" {
  source_json = data.aws_iam_policy_document.source.json

  statement {
    resources = [aws_sqs_queue.auth_queue.arn]
  }
}
