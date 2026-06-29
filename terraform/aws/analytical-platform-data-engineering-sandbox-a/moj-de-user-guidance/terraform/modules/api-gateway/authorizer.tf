# modules/api-gateway/authorizer.tf
# Lambda authorizer (conditional based on auth_token)

# ==================== Lambda Authorizer ====================

resource "aws_api_gateway_authorizer" "lambda" {
  count = local.enable_auth ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.chatbot.id
  name        = "lambda-authorizer"
  type        = "REQUEST"

  authorizer_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.authorizer_function_arn}/invocations"

  # No caching - validate every request
  authorizer_result_ttl_in_seconds = var.authorizer_cache_ttl

  # Extract token from Authorization header
  identity_source = "method.request.header.Authorization"
}

# ==================== Authorizer Lambda Permission ====================

resource "aws_lambda_permission" "authorizer_invoke" {
  count = local.enable_auth ? 1 : 0

  statement_id  = "apigateway-authorizer-invoke-${var.environment}" # Add environment
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  # restricted for specific lambda authorizer can invoke the Lambda instead of using any api gateway.
  source_arn = "${aws_api_gateway_rest_api.chatbot.execution_arn}/authorizers/${aws_api_gateway_authorizer.lambda[0].id}"
}
