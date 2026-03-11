output "lambda_name" {
  description = "The name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  description = "The ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "bucket_name" {
  description = "The name of the S3 bucket configured for the Lambda trigger."
  value       = var.bucket_name
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket configured for the Lambda trigger."
  value       = "arn:aws:s3:::${var.bucket_name}"
}
