# terraform/environments/dev/outputs.tf

# ==================== Bedrock Knowledge Base ====================

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock_kb.knowledge_base_id
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = module.bedrock_kb.knowledge_base_arn
}

output "collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.bedrock_kb.collection_endpoint
}

output "debug_caller_arn" {
  description = "Debug: Caller ARN"
  value       = module.bedrock_kb.debug_caller_arn
}

output "debug_assumed_role_name" {
  description = "Debug: Assumed role name"
  value       = module.bedrock_kb.debug_assumed_role_name
}

output "debug_caller_role_arn" {
  description = "Debug: Caller role ARN"
  value       = module.bedrock_kb.debug_caller_role_arn
}

# ==================== Lambda ====================

output "smart_rag_function_name" {
  description = "Main SmartRAG Lambda function name"
  value       = module.lambda.smart_rag_function_name
}

output "smart_rag_function_arn" {
  description = "Main SmartRAG Lambda function ARN"
  value       = module.lambda.smart_rag_function_arn
}

output "authorizer_function_name" {
  description = "Authorizer Lambda function name"
  value       = module.lambda.authorizer_function_name
}

output "authorizer_function_arn" {
  description = "Authorizer Lambda function ARN"
  value       = module.lambda.authorizer_function_arn
}

output "lambda_layer_arn" {
  description = "Lambda layer ARN"
  value       = module.lambda.layer_arn
}

# ==================== API Gateway ====================

output "api_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

output "api_endpoint" {
  description = "Base API Gateway endpoint"
  value       = module.api_gateway.api_endpoint
}

output "ask_endpoint" {
  description = "Full /ask endpoint URL"
  value       = module.api_gateway.ask_endpoint
}

output "feedback_endpoint" {
  description = "Full /feedback endpoint URL"
  value       = module.api_gateway.feedback_endpoint
}

output "auth_enabled" {
  description = "Whether API authentication is enabled"
  value       = module.api_gateway.auth_enabled
}

# ==================== Testing ====================

output "curl_test_command" {
  description = "Sample curl command to test the API"
  value       = module.api_gateway.curl_test_command
  sensitive   = true  # Hides from logs
}

# ==================== Summary ====================

output "deployment_summary" {
  description = "Complete deployment summary"
  value = <<-EOT
    
    ========================================
    MOJ GenAI App - Deployment Summary
    ========================================
    
    Knowledge Base:
       KB ID:        ${module.bedrock_kb.knowledge_base_id}
       S3 Bucket:    ${var.s3_bucket_name}
       AOSS:         ${module.bedrock_kb.collection_endpoint}
    
    Lambda Functions:
       Main:         ${module.lambda.smart_rag_function_name}
       Authorizer:   ${module.lambda.authorizer_function_name}
       Layer:        ${module.lambda.layer_arn}
    
    API Gateway:
       API ID:       ${module.api_gateway.api_id}
       Endpoint:     ${module.api_gateway.api_endpoint}
       Auth:         ✅ Enabled
    
    Endpoints:
       /ask:         ${module.api_gateway.ask_endpoint}
       /feedback:    ${module.api_gateway.feedback_endpoint}
    
    ========================================
  EOT
}