# modules/api-gateway/validators.tf
# Request validation for /ask endpoint

# ==================== Request Validator ====================

resource "aws_api_gateway_request_validator" "chatbot" {
  rest_api_id           = aws_api_gateway_rest_api.chatbot.id
  name                  = "chatbot-request-validator"
  validate_request_body = true
  validate_request_parameters = false
}

# ==================== Request Model ====================
# JSON Schema for /ask endpoint validation

resource "aws_api_gateway_model" "chatbot_request" {
  rest_api_id  = aws_api_gateway_rest_api.chatbot.id
  name         = "ChatbotRequestModel"
  description  = "Request schema for chatbot /ask endpoint"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    type      = "object"
    properties = {
      text = {
        type        = "string"
        minLength   = 1
        maxLength   = 2000
        description = "User question or message"
      }
    }
    required = ["text"]
  })
}