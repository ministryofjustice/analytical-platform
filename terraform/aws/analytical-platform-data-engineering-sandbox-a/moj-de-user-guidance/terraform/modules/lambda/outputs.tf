# terraform/modules/lambda/outputs.tf
# Output values from the Lambda module

# ==================== Function ARNs ====================

output "smart_rag_function_arn" {
  description = "ARN of the main SmartRAG Lambda function"
  value       = aws_lambda_function.smart_rag.arn
}

output "authorizer_function_arn" {
  description = "ARN of the authorizer Lambda function"
  value       = aws_lambda_function.authorizer.arn
}

# ==================== Function Names ====================

output "smart_rag_function_name" {
  description = "Name of the main SmartRAG Lambda function"
  value       = aws_lambda_function.smart_rag.function_name
}

output "authorizer_function_name" {
  description = "Name of the authorizer Lambda function"
  value       = aws_lambda_function.authorizer.function_name
}

# ==================== Invoke ARNs (for API Gateway) ====================

output "smart_rag_invoke_arn" {
  description = "Invoke ARN for API Gateway integration (main Lambda)"
  value       = aws_lambda_function.smart_rag.invoke_arn
}

output "authorizer_invoke_arn" {
  description = "Invoke ARN for API Gateway authorizer"
  value       = aws_lambda_function.authorizer.invoke_arn
}

# ==================== IAM Role ====================

output "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "lambda_role_id" {
  description = "ID of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.id
}

# ==================== Lambda Layer (Terraform-built) ====================

output "layer_arn" {
  description = "ARN of the Lambda dependencies layer"
  value       = aws_lambda_layer_version.dependencies.arn
}

output "layer_version" {
  description = "Version of the Lambda dependencies layer"
  value       = aws_lambda_layer_version.dependencies.version
}


# ==================== CloudWatch Log Groups ====================

output "smart_rag_log_group_name" {
  description = "CloudWatch log group name for main Lambda"
  value       = aws_cloudwatch_log_group.smart_rag.name
}

output "smart_rag_log_group_arn" {
  description = "CloudWatch log group ARN for main Lambda"
  value       = aws_cloudwatch_log_group.smart_rag.arn
}

output "authorizer_log_group_name" {
  description = "CloudWatch log group name for authorizer Lambda"
  value       = aws_cloudwatch_log_group.authorizer.name
}

output "authorizer_log_group_arn" {
  description = "CloudWatch log group ARN for authorizer Lambda"
  value       = aws_cloudwatch_log_group.authorizer.arn
}

# ==================== Computed Values ====================

output "smart_rag_log_group_url" {
  description = "Direct URL to CloudWatch logs for main Lambda"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#logsV2:log-groups/log-group/$252Faws$252Flambda$252F${aws_lambda_function.smart_rag.function_name}"
}