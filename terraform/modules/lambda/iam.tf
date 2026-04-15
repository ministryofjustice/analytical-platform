# Reference existing Lambda execution role and attach required policies

# ==================== Data Sources ====================

data "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_role_name
}

data "aws_caller_identity" "current" {}

# ==================== Bedrock Policy Attachment ====================

resource "aws_iam_role_policy_attachment" "bedrock_full_access" {
  role       = data.aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

# ==================== AOSS Access Policy ====================

resource "aws_iam_role_policy" "aoss_access" {
  name = "${var.project_name}-${var.environment}-lambda-aoss-access"
  role = data.aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll"
        ]
        Resource = "*"
      }
    ]
  })
}

# ==================== CloudWatch Logs Policy ====================

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-lambda-logs"
  role = data.aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
      },
      {
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
# For conversation logging (DynamoDBBackend)

resource "aws_iam_role_policy" "dynamodb_access" {
  name = "${var.project_name}-${var.environment}-lambda-dynamodb"
  role = data.aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:Query"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}",
          "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}/index/*"
        ]
      }
    ]
  })
}