resource "aws_sqs_queue_policy" "s3" {
  queue_url = aws_sqs_queue.s3.id
  policy    = data.aws_iam_policy_document.sqs_s3.json
}

resource "aws_sqs_queue_policy" "iam" {
  queue_url = aws_sqs_queue.iam.id
  policy    = data.aws_iam_policy_document.sqs_iam.json
}

resource "aws_sqs_queue_policy" "auth" {
  queue_url = aws_sqs_queue.auth.id
  policy    = data.aws_iam_policy_document.sqs_auth.json
}
