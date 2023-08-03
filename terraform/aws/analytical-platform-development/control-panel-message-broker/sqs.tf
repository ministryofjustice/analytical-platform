resource "aws_sqs_queue" "s3_queue" {
  name                      = "s3_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400

  tags = var.tags
}

resource "aws_sqs_queue" "iam_queue" {
  name                      = "iam_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400

  tags = var.tags
}

resource "aws_sqs_queue" "auth_queue" {
  name                      = "auth_queue"
  max_message_size          = 2048
  message_retention_seconds = 86400

  tags = var.tags
}
