# modules/api-gateway/permissions.tf
# Lambda invoke permissions for API Gateway

# ==================== Main Lambda Permission ====================

resource "aws_lambda_permission" "smart_rag_invoke" {
  statement_id  = "apigateway-invoke-${var.environment}"
  action        = "lambda:InvokeFunction"
  function_name = var.smart_rag_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot.execution_arn}/*/*" # stage/method/resource

  depends_on = [aws_api_gateway_stage.this]

}
