resource "aws_sqs_queue" "s3" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "control-panel-s3"
}

resource "aws_sqs_queue" "iam" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "control-panel-iam"
}

resource "aws_sqs_queue" "auth" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name = "control-panel-auth"
}
