resource "aws_sqs_queue" "s3_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "s3_queue"

  tags = var.tags
}

resource "aws_sqs_queue" "iam_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "iam_queue"

  tags = var.tags
}

resource "aws_sqs_queue" "auth_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "auth_queue"

  tags = var.tags
}
