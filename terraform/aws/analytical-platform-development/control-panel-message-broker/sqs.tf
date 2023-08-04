resource "aws_sqs_queue" "s3_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570

  name                      = "s3_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

resource "aws_sqs_queue" "iam_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570

  name                      = "iam_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  sqs_managed_sse_enabled   = true

  tags = var.tags
}

resource "aws_sqs_queue" "auth_queue" {
  #ts:skip=AWS.SQS.NetworkSecurity.High.0570

  name                      = "auth_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400
  sqs_managed_sse_enabled   = true

  tags = var.tags
}
