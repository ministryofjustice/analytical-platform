# Referencing existing role

# modules/lambda/iam.tf
# Reference existing Lambda execution role (created by deploy_lambda.py)

# ==================== Data Source for Existing Role ====================

data "aws_iam_role" "lambda_execution_role" {
  name = var.lambda_role_name
}

# ==================== Bedrock Policy Attachment ====================
# Ensures Bedrock permissions are attached (matches deploy_lambda.py behavior)

resource "aws_iam_role_policy_attachment" "bedrock_full_access" {
  role       = data.aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
}

# ==================== AOSS Access Policy ====================
# Allows Lambda to query OpenSearch Serverless

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
# Basic execution role for logging

resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.project_name}-${var.environment}-lambda-logs"
  role = data.aws_iam_role.lambda_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.region}:*:*"
      }
    ]
  })
}

#data.aws_iam_role	References existing role (no import needed)
# bedrock_full_access	Matches Python script behavior
# aoss_access	Query OpenSearch Serverless
# cloudwatch_logs	Lambda logging