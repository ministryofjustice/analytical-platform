# terraform/modules/lambda/iam.tf
# IAM Role and Policies for Lambda functions
#
# This replaces:
# - ensure_bedrock_permissions() from deploy_lambda.py
# - ensure_dynamodb_permissions() from deploy_lambda.py

data "aws_caller_identity" "current" {}

# ==================== Lambda Execution Role ====================
# Single role shared by both Lambda functions

resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowLambdaAssumeRole"
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-execution-role"
  })
}

# ==================== Basic Lambda Execution Policy ====================
# Allows Lambda to write logs to CloudWatch

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ==================== Bedrock Policy ====================
# Replaces: ensure_bedrock_permissions() from POC
# Required for: Model invocation and Knowledge Base queries

resource "aws_iam_role_policy_attachment" "bedrock_full_access" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

# Alternative: More restrictive Bedrock policy (uncomment if preferred)
# resource "aws_iam_role_policy" "bedrock_access" {
#   name = "${var.project_name}-${var.environment}-lambda-bedrock"
#   role = aws_iam_role.lambda_execution.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Sid    = "BedrockModelInvocation"
#         Effect = "Allow"
#         Action = [
#           "bedrock:InvokeModel",
#           "bedrock:InvokeModelWithResponseStream"
#         ]
#         Resource = [
#           "arn:aws:bedrock:${var.region}::foundation-model/${var.model_id}",
#           "arn:aws:bedrock:${var.region}::foundation-model/*"
#         ]
#       },
#       {
#         Sid    = "BedrockKnowledgeBase"
#         Effect = "Allow"
#         Action = [
#           "bedrock:Retrieve",
#           "bedrock:RetrieveAndGenerate"
#         ]
#         Resource = [
#           "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/${var.kb_id}"
#         ]
#       }
#     ]
#   })
# }

# ==================== CloudWatch Logs Policy ====================
# Allows Lambda to create log streams and write logs

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-lambda-cloudwatch-logs"
  role = aws_iam_role.lambda_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CreateLogGroup"
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
        Sid    = "WriteLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.smart_rag.arn}:*",
          "${aws_cloudwatch_log_group.authorizer.arn}:*"
        ]
      }
    ]
  })
}

# ==================== DynamoDB Policy ====================
# Replaces: ensure_dynamodb_permissions() from POC
# Required for: Conversation logging

resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.project_name}-${var.environment}-lambda-dynamodb"
  role = aws_iam_role.lambda_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "DynamoDBConversationLogging"
      Effect = "Allow"
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query",
        "dynamodb:DescribeTable"
      ]
      Resource = [
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}",
        "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}/index/*"
      ]
    }]
  })
}

# ==================== OpenSearch Serverless (AOSS) Policy ====================
# Required for: Direct queries to OpenSearch if not using Bedrock KB API
# Only created when AOSS collection ARN is provided

resource "aws_iam_role_policy" "aoss_access" {
  count = var.aoss_collection_arn != "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-aoss"
  role = aws_iam_role.lambda_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid      = "OpenSearchServerlessAccess"
      Effect   = "Allow"
      Action   = "aoss:APIAccessAll"
      Resource = var.aoss_collection_arn
    }]
  })
}

# ==================== S3 Policy (Optional) ====================
# Only needed if Lambda accesses S3 directly (not via Bedrock KB)
# Uncomment if required

# resource "aws_iam_role_policy" "s3_access" {
#   count = var.s3_bucket_name != "" ? 1 : 0
#
#   name = "${var.project_name}-${var.environment}-lambda-s3"
#   role = aws_iam_role.lambda_execution.name
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Sid    = "S3ReadAccess"
#       Effect = "Allow"
#       Action = [
#         "s3:GetObject",
#         "s3:ListBucket"
#       ]
#       Resource = [
#         "arn:aws:s3:::${var.s3_bucket_name}",
#         "arn:aws:s3:::${var.s3_bucket_name}/*"
#       ]
#     }]
#   })
# }

# ==================== Guardrails Policy (Optional) ====================
# Only needed if using custom Bedrock Guardrails

resource "aws_iam_role_policy" "guardrails_access" {
  count = var.enable_guardrails ? 1 : 0

  name = "${var.project_name}-${var.environment}-lambda-guardrails"
  role = aws_iam_role.lambda_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "BedrockGuardrailsAccess"
      Effect = "Allow"
      Action = [
        "bedrock:ApplyGuardrail"
      ]
      Resource = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:guardrail/*"
    }]
  })
}

# ==================== Secrets Manager Policy ====================
resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "${var.project_name}-${var.environment}-lambda-secrets"
  role = aws_iam_role.lambda_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "SecretsManagerAccess"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = [
        "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:genai-data-eng-assistant-dev/*"
      ]
    }]
  })
}
