# terraform/modules/lambda/main.tf
# Lambda functions for SmartRAG

locals {
  function_name            = "${var.project_name}-${var.environment}-smart-rag"
  authorizer_function_name = "${var.project_name}-${var.environment}-smart-rag-authorizer"
}

# ==================== Main Lambda Function ====================
# This is the RAG backend that handles queries

resource "aws_lambda_function" "smart_rag" {
  function_name = local.function_name
  description   = "SmartRAG backend for Data Engineering Support Assistant"
  
  # IAM Role (created in iam.tf)
  role = aws_iam_role.lambda_execution.arn
  
  # Runtime configuration
  handler     = "lambda_handler.lambda_handler"
  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory
  
  # Placeholder code - actual code deployed via deploy_lambda.py
  # This allows Terraform to create the function structure
  # Real code is uploaded separately for faster iterations
  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256
  
  # Lambda Layer for dependencies
  layers = var.use_existing_layer ? [data.aws_lambda_layer_version.dependencies[0].arn] : []
  
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
# JWT/Token authorizer for API Gateway

resource "aws_lambda_function" "authorizer" {
  function_name = local.authorizer_function_name
  description   = "Token authorizer for SmartRAG API Gateway"
  
  # IAM Role (same role as main Lambda)
  role = aws_iam_role.lambda_execution.arn
  
  # Runtime configuration
  # Note: Handler assumes lambda_authorizer.py is at root level in the ZIP
  handler     = "lambda_authorizer.lambda_handler"
  runtime     = var.lambda_runtime
  timeout     = 10  # Authorizers should be fast
  memory_size = 256 # Authorizers don't need much memory
  
  # Placeholder code - actual code deployed separately
  filename         = data.archive_file.authorizer_placeholder.output_path
  source_code_hash = data.archive_file.authorizer_placeholder.output_base64sha256
  
  # Environment variables for authorization
  environment {
    variables = {
      AUTH_TOKEN    = var.auth_token
      LOG_LEVEL     = var.log_level
      # Add these if using OIDC/JWT validation
      # OIDC_ISSUER   = var.oidc_issuer
      # OIDC_AUDIENCE = var.oidc_audience
    }
  }
  
  tags = merge(var.tags, {
    Name        = local.authorizer_function_name
    Description = "SmartRAG API Gateway authorizer"
  })
  
  depends_on = [
    aws_cloudwatch_log_group.authorizer,
    aws_iam_role_policy.cloudwatch_logs,
    aws_iam_role_policy_attachment.lambda_basic 
  ]
}

# ==================== Placeholder Archives ====================
# Creates minimal zip files for initial Terraform apply
# Actual code is deployed via deploy_lambda.py for faster iterations

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content  = <<-EOF
      # Placeholder for SmartRAG Lambda
      # Deploy actual code via: python deployment/deploy_lambda.py
      
      def lambda_handler(event, context):
          return {
              'statusCode': 503,
              'body': 'Function not yet deployed. Run deploy_lambda.py'
          }
    EOF
    filename = "lambda_handler.py"
  }
}

data "archive_file" "authorizer_placeholder" {
  type        = "zip"
  output_path = "${path.module}/authorizer_placeholder.zip"
  
  source {
    content  = <<-EOF
      # Placeholder for Authorizer Lambda
      # Deploy actual code via: python deployment/deploy_authorizer.py
      
      def lambda_handler(event, context):
          return {
              'principalId': 'placeholder',
              'policyDocument': {
                  'Version': '2012-10-17',
                  'Statement': [{
                      'Action': 'execute-api:Invoke',
                      'Effect': 'Deny',
                      'Resource': '*'
                  }]
              }
          }
    EOF
    filename = "lambda_authorizer.py"
  }
}


