# terraform/modules/lambda/main.tf

terraform {
  required_version = ">= 1.5.0"
}

# Lambda functions for SmartRAG
#
# Code packaging is NOT done by Terraform. Artifacts are pre-built + uploaded
# to the bootstrap-owned artifacts bucket by build_and_upload.sh (source repo).
#
#   data.aws_s3_object.layer / function / authorizer → look up pre-staged zips
#   aws_lambda_layer_version.dependencies            → layer from S3
#   aws_lambda_function.*                            → functions from S3
#
# This keeps the infra repo free of source code (infra-only).

locals {
  function_name            = "${var.project_name}-${var.environment}-smart-rag"
  authorizer_function_name = "${var.project_name}-${var.environment}-smart-rag-authorizer"
}

# ==================== Dependency Layer (from S3) ====================
resource "aws_lambda_layer_version" "dependencies" {
  layer_name               = "${var.project_name}-${var.environment}-dependencies"
  description              = "Python dependencies for SmartRAG (pre-built, S3-staged)"
  compatible_runtimes      = [var.lambda_runtime]
  compatible_architectures = ["x86_64"]

  s3_bucket        = var.artifacts_bucket
  s3_key           = var.layer_s3_key
  source_code_hash = data.aws_s3_object.layer.etag
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

  # Code from S3 (pre-staged by source-repo build script)
  s3_bucket        = var.artifacts_bucket
  s3_key           = var.function_s3_key
  source_code_hash = data.aws_s3_object.function.etag

  # Dependency layer (from S3)
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

  # Code from S3 (pre-staged by source-repo build script)
  s3_bucket        = var.artifacts_bucket
  s3_key           = var.authorizer_s3_key
  source_code_hash = data.aws_s3_object.authorizer.etag

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
  ]
}
