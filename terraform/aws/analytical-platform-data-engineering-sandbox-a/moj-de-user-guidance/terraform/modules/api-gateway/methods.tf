# modules/api-gateway/methods.tf
# POST methods for /ask and /feedback

# ==================== POST /ask ====================

resource "aws_api_gateway_method" "ask_post" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot.id
  resource_id   = aws_api_gateway_resource.ask.id
  http_method   = "POST"
  authorization = local.enable_auth ? "CUSTOM" : "NONE"
  authorizer_id = local.enable_auth ? aws_api_gateway_authorizer.lambda[0].id : null

  # Request validation (only for /ask)
  request_validator_id = aws_api_gateway_request_validator.chatbot.id
  request_models = {
    "application/json" = aws_api_gateway_model.chatbot_request.name
  }

  api_key_required = false
}

resource "aws_api_gateway_method_response" "ask_post_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot.id
  resource_id = aws_api_gateway_resource.ask.id
  http_method = aws_api_gateway_method.ask_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration" "ask_post" {
  rest_api_id             = aws_api_gateway_rest_api.chatbot.id
  resource_id             = aws_api_gateway_resource.ask.id
  http_method             = aws_api_gateway_method.ask_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.smart_rag_function_arn}/invocations"
}

# ==================== POST /feedback ====================

resource "aws_api_gateway_method" "feedback_post" {
  rest_api_id   = aws_api_gateway_rest_api.chatbot.id
  resource_id   = aws_api_gateway_resource.feedback.id
  http_method   = "POST"
  authorization = local.enable_auth ? "CUSTOM" : "NONE"
  authorizer_id = local.enable_auth ? aws_api_gateway_authorizer.lambda[0].id : null

  # No validation for feedback (different schema)
  api_key_required = false
}

resource "aws_api_gateway_method_response" "feedback_post_200" {
  rest_api_id = aws_api_gateway_rest_api.chatbot.id
  resource_id = aws_api_gateway_resource.feedback.id
  http_method = aws_api_gateway_method.feedback_post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = false
  }
}

resource "aws_api_gateway_integration" "feedback_post" {
  rest_api_id             = aws_api_gateway_rest_api.chatbot.id
  resource_id             = aws_api_gateway_resource.feedback.id
  http_method             = aws_api_gateway_method.feedback_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.smart_rag_function_arn}/invocations"
}