resource "aws_iam_role" "bedrock_kb_role" {
  name = local.kb_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_policy" "bedrock_kb_policy" {
  name = local.kb_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = [local.embedding_model_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [local.s3_bucket_arn]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${local.s3_bucket_arn}/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["aoss:APIAccessAll"]
        Resource = [aws_opensearchserverless_collection.vector.arn]
      }
    ]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.bedrock_kb_role.name
  policy_arn = aws_iam_policy.bedrock_kb_policy.arn
}
