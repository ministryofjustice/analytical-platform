resource "aws_sqs_queue" "s3" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "s3_queue"
}

resource "aws_sqs_queue" "iam" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "iam_queue"
}

resource "aws_sqs_queue" "auth" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "auth_queue"
}
