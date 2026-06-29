# modules/api-gateway/main.tf
# REST API Gateway setup

locals {
  api_name    = "${var.project_name}-${var.environment}-api"
  stage_name  = var.stage_name != "" ? var.stage_name : var.environment
  enable_auth = var.auth_token != ""
  #account_id      = data.aws_caller_identity.current.account_id
}

# ==================== Data Sources ====================

data "aws_caller_identity" "current" {}

# ==================== REST API ====================

resource "aws_api_gateway_rest_api" "chatbot" {
  name        = local.api_name
  description = "REST API Gateway for ${var.project_name} Lambda chatbot"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.tags, {
    Name = local.api_name
  })
}

# ==================== Resources ====================

# /ask resource
resource "aws_api_gateway_resource" "ask" {
  rest_api_id = aws_api_gateway_rest_api.chatbot.id
  parent_id   = aws_api_gateway_rest_api.chatbot.root_resource_id
  path_part   = "ask"
}

# /feedback resource
resource "aws_api_gateway_resource" "feedback" {
  rest_api_id = aws_api_gateway_rest_api.chatbot.id
  parent_id   = aws_api_gateway_rest_api.chatbot.root_resource_id
  path_part   = "feedback"
}

# ==================== Deployment ====================

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.chatbot.id

  # Force redeployment when methods change
  triggers = {
    redeployment = sha256(jsonencode([
      aws_api_gateway_integration.ask_post.id,
      aws_api_gateway_integration.feedback_post.id,
      aws_api_gateway_integration.ask_options.id,
      aws_api_gateway_integration.feedback_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.ask_post,
    aws_api_gateway_method.feedback_post,
    aws_api_gateway_method.ask_options,
    aws_api_gateway_method.feedback_options,
  ]
}

# ==================== Stage ====================

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.chatbot.id
  stage_name    = var.stage_name

  # Disable caching (matches Python script behavior)
  cache_cluster_enabled = false

  tags = merge(var.tags, {
    Name = "${local.api_name}-${var.stage_name}"
  })
}

# ==================== Lambda Permissions ====================

# Permission for API Gateway to invoke RAG Lambda
resource "aws_lambda_permission" "api_gateway_rag" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.smart_rag_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot.execution_arn}/*/*"
}

# Permission for API Gateway to invoke Authorizer Lambda
resource "aws_lambda_permission" "api_gateway_authorizer" {
  statement_id  = "AllowAPIGatewayAuthorizer"
  action        = "lambda:InvokeFunction"
  function_name = var.authorizer_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.chatbot.execution_arn}/authorizers/*"
}