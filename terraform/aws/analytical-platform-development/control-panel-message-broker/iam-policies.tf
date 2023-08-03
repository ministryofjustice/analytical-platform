resource "aws_sqs_queue_policy" "s3_queue_iam_policy" {
  queue_url = "${aws_sqs_queue.s3_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "CanManageSqsMessages",
      "Effect": "Allow",
      "Principal": "*",
      "Action" : [
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": ""arn:aws:sqs::${var.account_ids["analytical-platform-development"]}:*""
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "iam_queue_iam_policy" {
  queue_url = "${aws_sqs_queue.iam_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "CanManageSqsMessages",
      "Effect": "Allow",
      "Principal": "*",
      "Action" : [
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": ""arn:aws:sqs::${var.account_ids["analytical-platform-development"]}:*""
    }
  ]
}
POLICY
}

resource "aws_sqs_queue_policy" "auth_queue_iam_policy" {
  queue_url = "${aws_sqs_queue.auth_queue.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "CanManageSqsMessages",
      "Effect": "Allow",
      "Principal": "*",
      "Action" : [
          "sqs:GetQueueUrl",
          "sqs:DeleteMessage",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
      "Resource": ""arn:aws:sqs::${var.account_ids["analytical-platform-development"]}:*""
    }
  ]
}
POLICY
}