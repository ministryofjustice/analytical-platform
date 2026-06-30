# terraform/environments/dev/outputs.tf

# ==================== Database (DynamoDB) ====================

output "dynamodb_table_name" {
  description = "DynamoDB table name"
  value       = module.database.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.database.table_arn
}

output "dynamodb_stream_arn" {
  description = "DynamoDB stream ARN"
  value       = module.database.stream_arn
}

# ==================== Security (Guardrails) ====================

output "guardrail_id" {
  description = "Bedrock Guardrail ID"
  value       = module.security.guardrail_id
}

output "guardrail_version" {
  description = "Bedrock Guardrail Version"
  value       = module.security.guardrail_version
}

# ==================== Bedrock Knowledge Base ====================

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = try(module.bedrock_kb.knowledge_base_id, "KB creation skipped")
}

output "knowledge_base_arn" {
  description = "Bedrock Knowledge Base ARN"
  value       = try(module.bedrock_kb.knowledge_base_arn, "KB creation skipped")
}

output "collection_endpoint" {
  description = "OpenSearch Serverless collection endpoint"
  value       = module.bedrock_kb.collection_endpoint
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

# ==================== GitHub Actions role ====================

output "github_actions_role_arn" {
  description = "GitHub Actions IAM role ARN"
  value       = module.security.github_actions_role_arn
}

# ==================== Deployment Summary ====================

locals {
  kb_id_display = module.bedrock_kb.knowledge_base_id != null ? module.bedrock_kb.knowledge_base_id : "SKIPPED"
}

output "deployment_summary" {
  description = "Complete deployment summary"
  value       = <<-EOT

    ========================================
    MOJ GenAI App - Deployment Summary
    ========================================

    Database:
       Table:        ${module.database.table_name}
       Streams:      Enabled
       PITR:         Enabled

    Security:
       Guardrail:    ${module.security.guardrail_id}
       Version:      ${module.security.guardrail_version}

    Knowledge Base:
       KB ID:        ${local.kb_id_display}
       S3 Bucket:    ${var.s3_bucket_name}
       AOSS:         ${module.bedrock_kb.collection_endpoint}

    Lambda Functions:
       Main:         ${module.lambda.smart_rag_function_name}
       Authorizer:   ${module.lambda.authorizer_function_name}

    API Gateway:
       Endpoint:     ${module.api_gateway.api_endpoint}
       /ask:         ${module.api_gateway.ask_endpoint}
       /feedback:    ${module.api_gateway.feedback_endpoint}

    ========================================
  EOT
}
