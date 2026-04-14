# modules/api-gateway/permissions.tf
# Lambda invoke permissions for API Gateway

# ==================== Main Lambda Permission ====================

resource "aws_lambda_permission" "smart_rag_invoke" {
  statement_id  = "apigateway-invoke-permission"
  action        = "lambda:InvokeFunction"
  function_name = var.smart_rag_function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any method/resource in this API
  source_arn = "${aws_api_gateway_rest_api.chatbot.execution_arn}/*/*"
}