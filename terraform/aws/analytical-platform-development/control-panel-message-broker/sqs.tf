resource "aws_sqs_queue" "s3" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name                    = "control-panel-s3"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "iam" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name                    = "control-panel-iam"
  sqs_managed_sse_enabled = true
}

resource "aws_sqs_queue" "auth" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570
  name                    = "control-panel-auth"
  sqs_managed_sse_enabled = true
}
