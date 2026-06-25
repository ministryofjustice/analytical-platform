# terraform/modules/lambda/main.tf
# Lambda functions for SmartRAG
#
# Code packaging handled in build.tf:
#   null_resource.build_layer / build_function  → pip install + stage code
#   data.archive_file.layer / function / authorizer → zip
#   aws_s3_object.layer / function / authorizer → upload to bucket #3 (aws_s3_bucket.artifacts)
#   aws_lambda_layer_version.dependencies → layer from S3
#
# Single `terraform apply` builds, uploads, and deploys all code.
# Manual Phase 5 (create_lambda_layer.py + deploy_lambda.py) is no longer required.

locals {
  function_name            = "${var.project_name}-${var.environment}-smart-rag"
  authorizer_function_name = "${var.project_name}-${var.environment}-smart-rag-authorizer"
}

# ==================== Main Lambda Function ====================
# RAG backend that handles queries.

resource "aws_lambda_function" "smart_rag" {
  function_name = local.function_name
  description   = "SmartRAG backend for Data Engineering Support Assistant"

  # IAM Role (created in iam.tf)
  role = aws_iam_role.lambda_execution.arn

  # Runtime configuration
  handler       = "lambda_handler.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory
  architectures = ["x86_64"]

  # Code from S3 (built + uploaded in build.tf)
  s3_bucket        = aws_s3_bucket.artifacts.id
  s3_key           = aws_s3_object.function.key
  source_code_hash = data.archive_file.function.output_base64sha256

  # Dependency layer (built + uploaded in build.tf)
  layers = [aws_lambda_layer_version.dependencies.arn]

  # Environment variables for the RAG application
  environment {
    variables = {
      KB_ID               = var.kb_id
      MODEL_ID            = var.model_id
      MAX_CONTEXT_TOKENS  = tostring(var.max_context_tokens)
      AOSS_ENDPOINT       = var.aoss_collection_endpoint
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      GUARDRAIL_ID        = var.guardrail_id
      GUARDRAIL_VERSION   = var.guardrail_version
      LOG_LEVEL           = var.log_level
    }
  }

  tags = merge(var.tags, {
    Name        = local.function_name
    Description = "SmartRAG main Lambda function"
  })

  depends_on = [
    aws_cloudwatch_log_group.smart_rag,
    aws_iam_role_policy_attachment.bedrock_full_access,
    aws_iam_role_policy.dynamodb_access,
    aws_iam_role_policy.cloudwatch_logs,
    aws_s3_object.function,
  ]
}

# ==================== Authorizer Lambda Function ====================
# Bearer token authorizer for API Gateway.

resource "aws_lambda_function" "authorizer" {
  function_name = local.authorizer_function_name
  description   = "Token authorizer for SmartRAG API Gateway"

  # IAM Role (same role as main Lambda)
  role = aws_iam_role.lambda_execution.arn

  # Runtime configuration
  # Handler assumes lambda_authorizer.py is at root level in the ZIP.
  handler       = "lambda_authorizer.lambda_handler"
  runtime       = var.lambda_runtime
  timeout       = 10  # Authorizers should be fast
  memory_size   = 256 # Authorizers don't need much memory
  architectures = ["x86_64"]

  # Code from S3 (built + uploaded in build.tf)
  s3_bucket        = aws_s3_bucket.artifacts.id
  s3_key           = aws_s3_object.authorizer.key
  source_code_hash = data.archive_file.authorizer.output_base64sha256

  # Environment variables for authorization
  environment {
    variables = {
      AUTH_TOKEN = var.auth_token
      LOG_LEVEL  = var.log_level
    }
  }

  tags = merge(var.tags, {
    Name        = local.authorizer_function_name
    Description = "SmartRAG API Gateway authorizer"
  })

  depends_on = [
    aws_cloudwatch_log_group.authorizer,
    aws_iam_role_policy.cloudwatch_logs,
    aws_iam_role_policy_attachment.lambda_basic,
    aws_s3_object.authorizer,
  ]
}
