output "auth_queue_url" {
  value     = aws_sqs_queue.auth_queue.url
  sensitive = true
}

output "iam_queue_url" {
  value     = aws_sqs_queue.iam_queue.url
  sensitive = true
}

output "s3_queue_url" {
  value     = aws_sqs_queue.s3_queue.url
  sensitive = true
}
