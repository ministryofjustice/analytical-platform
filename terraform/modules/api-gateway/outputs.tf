# modules/api-gateway/outputs.tf

# ==================== API Details ====================

output "api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.chatbot.id
}

output "api_name" {
  description = "API Gateway REST API name"
  value       = aws_api_gateway_rest_api.chatbot.name
}

output "api_arn" {
  description = "API Gateway ARN"
  value       = aws_api_gateway_rest_api.chatbot.arn
}

# ==================== Endpoints ====================

output "api_endpoint" {
  description = "Base API endpoint URL"
  value       = aws_api_gateway_stage.prod.invoke_url
}

output "ask_endpoint" {
  description = "Full /ask endpoint URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/ask"
}

output "feedback_endpoint" {
  description = "Full /feedback endpoint URL"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/feedback"
}

# ==================== Stage ====================

output "stage_name" {
  description = "Deployed stage name"
  value       = aws_api_gateway_stage.prod.stage_name
}

# ==================== Auth Status ====================

output "auth_enabled" {
  description = "Whether authentication is enabled"
  value       = local.enable_auth
}

output "authorizer_id" {
  description = "Lambda authorizer ID (if enabled)"
  value       = local.enable_auth ? aws_api_gateway_authorizer.lambda[0].id : null
}

# ==================== Testing ====================

output "curl_test_command" {
  description = "Sample curl command to test the API"
  value = local.enable_auth ? <<-EOT
    curl -X POST ${aws_api_gateway_stage.prod.invoke_url}/ask \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer YOUR_TOKEN" \
      -d '{"text": "What is R-studio?"}'
  EOT
  : <<-EOT
    curl -X POST ${aws_api_gateway_stage.prod.invoke_url}/ask \
      -H "Content-Type: application/json" \
      -d '{"text": "What is R-studio?"}'
  EOT
}