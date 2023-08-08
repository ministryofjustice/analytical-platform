resource "aws_sqs_queue_policy" "s3_queue_iam_policy" {
  queue_url = aws_sqs_queue.s3_queue.id
  policy    = data.aws_iam_policy_document.sqs_s3_policy_document.json
}

resource "aws_sqs_queue_policy" "iam_queue_iam_policy" {
  queue_url = aws_sqs_queue.iam_queue.id
  policy    = data.aws_iam_policy_document.sqs_iam_policy_document.json
}

resource "aws_sqs_queue_policy" "auth_queue_iam_policy" {
  queue_url = aws_sqs_queue.auth_queue.id
  policy    = data.aws_iam_policy_document.sqs_auth_policy_document.json
}
