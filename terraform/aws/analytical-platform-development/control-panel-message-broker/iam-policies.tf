resource "aws_sqs_queue_policy" "s3_queue_iam_policy" {
  queue_url = aws_sqs_queue.s3_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "InboundManagementSqsMessages",
      "Effect": "Allow",
      "Principal": {
         "AWS": "${local.control_panel_api_arn}"
      },
      "Action" : [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": "${aws_sqs_queue.s3_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "iam_queue_iam_policy" {
  queue_url = aws_sqs_queue.iam_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "InboundManagementSqsMessages",
      "Effect": "Allow",
      "Principal": {
         "AWS": "${local.control_panel_api_arn}"
      },
      "Action" : [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": "${aws_sqs_queue.iam_queue.arn}"
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "auth_queue_iam_policy" {
  queue_url = aws_sqs_queue.auth_queue.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "InboundManagementSqsMessages",
      "Effect": "Allow",
      "Principal": {
         "AWS": "${local.control_panel_api_arn}"
      },
      "Action" : [
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": "${aws_sqs_queue.auth_queue.arn}"
    }
  ]
}
POLICY
}
