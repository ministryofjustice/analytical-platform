output "auth_queue_url" {
  value     = aws_sqs_queue.auth.url
  sensitive = true
}

output "iam_queue_url" {
  value     = aws_sqs_queue.iam.url
  sensitive = true
}

output "s3_queue_url" {
  value     = aws_sqs_queue.s3.url
  sensitive = true
}
