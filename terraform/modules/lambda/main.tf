# Both lambda function resources
# modules/lambda/main.tf
# Lambda functions for SmartRAG

locals {
  function_name            = "${var.project_name}-${var.environment}-smart-rag"
  authorizer_function_name = "${var.project_name}-${var.environment}-smart-rag-authorizer"
}

# ==================== Main Lambda Function ====================

resource "aws_lambda_function" "smart_rag" {
  function_name = local.function_name
  role          = data.aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_handler.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  # Placeholder - code deployed via Python script
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  layers = [data.aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = {
      KB_ID               = var.kb_id
      MODEL_ID            = var.model_id
      MAX_CONTEXT_TOKENS  = tostring(var.max_context_tokens)
      AOSS_ENDPOINT       = var.aoss_collection_endpoint
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      GUARDRAIL_ID        = var.guardrail_id        
      GUARDRAIL_VERSION   = var.guardrail_version   
    }
  }

  tags = merge(var.tags, {
    Name = local.function_name
  })

  depends_on = [
    aws_cloudwatch_log_group.smart_rag
  ]
}

# ==================== Authorizer Lambda Function ====================

resource "aws_lambda_function" "authorizer" {
  function_name = local.authorizer_function_name
  role          = data.aws_iam_role.lambda_execution_role.arn
  handler       = "deployment/lambda_authorizer.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory

  # Placeholder - code deployed via Python script
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  layers = [data.aws_lambda_layer_version.dependencies.arn]

  environment {
    variables = {
      AUTH_TOKEN = var.auth_token
    }
  }

  tags = merge(var.tags, {
    Name = local.authorizer_function_name
  })

  depends_on = [
    aws_cloudwatch_log_group.authorizer
  ]
}

# ==================== Placeholder Archive ====================
# Creates minimal zip for initial Terraform apply
# Actual code deployed via deploy_lambda.py

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    content  = "# Placeholder - deploy code via deploy_lambda.py"
    filename = "lambda_handler.py"
  }
}

# Placeholder zip:	Required for initial terraform apply
# Layers:	Auto-attached from data source
# Actual code:	Deployed via existing Python script
# Environment variables:	All required vars included