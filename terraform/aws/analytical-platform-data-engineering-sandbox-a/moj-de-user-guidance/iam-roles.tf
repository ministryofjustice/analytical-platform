resource "aws_iam_role" "lambda_smart_rag" {
  name = "lambda-smart-rag-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda_smart_rag_cloudwatch_logs" {
  role = aws_iam_role.lambda_smart_rag.name
  name = "AWSLambdaBasicExecutionRole-f714bd22-0c83-4d12-97f2-0613c4d5ab47"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:eu-west-2:684969100054:*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:eu-west-2:684969100054:log-group:/aws/lambda/lambda_smart_rag:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_smart_rag_bedrock_access" {
  role = aws_iam_role.lambda_smart_rag.name
  name = "BedrockAccess"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockModelAccess"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:eu-west-2::foundation-model/anthropic.claude-3-sonnet-20240229-v1:0",
          "arn:aws:bedrock:eu-west-2::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0",
          "arn:aws:bedrock:eu-west-2::foundation-model/*"
        ]
      },
      {
        Sid    = "BedrockKnowledgeBaseAccess"
        Effect = "Allow"
        Action = [
          "bedrock:Retrieve",
          "bedrock:RetrieveAndGenerate"
        ]
        Resource = [
          "arn:aws:bedrock:eu-west-2:684969100054:knowledge-base/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_smart_rag_s3_access" {
  role = aws_iam_role.lambda_smart_rag.name
  name = "lambda-smart-rag-s3-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.moj_de_user_guidance.s3_bucket_arn,
          "${module.moj_de_user_guidance.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}
