#ARNs, function names
# modules/lambda/outputs.tf

# ==================== Function ARNs ====================

output "smart_rag_function_arn" {
  description = "ARN of main SmartRAG Lambda function"
  value       = aws_lambda_function.smart_rag.arn
}

output "authorizer_function_arn" {
  description = "ARN of authorizer Lambda function"
  value       = aws_lambda_function.authorizer.arn
}

# ==================== Function Names ====================

output "smart_rag_function_name" {
  description = "Name of main SmartRAG Lambda function"
  value       = aws_lambda_function.smart_rag.function_name
}

output "authorizer_function_name" {
  description = "Name of authorizer Lambda function"
  value       = aws_lambda_function.authorizer.function_name
}

# ==================== Invoke ARNs (for API Gateway) ====================

output "smart_rag_invoke_arn" {
  description = "Invoke ARN for API Gateway integration"
  value       = aws_lambda_function.smart_rag.invoke_arn
}

output "authorizer_invoke_arn" {
  description = "Invoke ARN for API Gateway authorizer"
  value       = aws_lambda_function.authorizer.invoke_arn
}

# ==================== IAM Role ====================

output "lambda_role_arn" {
  description = "Lambda execution role ARN"
  value       = data.aws_iam_role.lambda_execution_role.arn
}

# ==================== Layer ====================

output "layer_arn" {
  description = "Lambda layer ARN"
  value       = data.aws_lambda_layer_version.dependencies.arn
}