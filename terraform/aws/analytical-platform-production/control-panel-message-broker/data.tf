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

data "aws_iam_policy_document" "sqs_iam" {
  source_policy_documents = [data.aws_iam_policy_document.source.json]

  statement {
    resources = [aws_sqs_queue.iam.arn]
  }
}

data "aws_iam_policy_document" "sqs_s3" {
  source_policy_documents = [data.aws_iam_policy_document.source.json]

  statement {
    resources = [aws_sqs_queue.s3.arn]
  }
}

data "aws_iam_policy_document" "sqs_auth" {
  source_policy_documents = [data.aws_iam_policy_document.source.json]

  statement {
    resources = [aws_sqs_queue.auth.arn]
  }
}
