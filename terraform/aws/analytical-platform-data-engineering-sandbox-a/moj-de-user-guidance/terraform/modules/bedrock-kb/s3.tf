# Use existing bucket
data "aws_s3_bucket" "existing" {
  count  = var.create_s3_bucket ? 0 : 1
  bucket = var.s3_bucket_name
}

# Create new bucket
resource "aws_s3_bucket" "knowledge_base" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = var.s3_bucket_name
  tags   = local.common_tags
}

resource "aws_s3_bucket_versioning" "knowledge_base" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.knowledge_base[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "knowledge_base" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.knowledge_base[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "knowledge_base" {
  count                   = var.create_s3_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.knowledge_base[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy 
resource "aws_s3_bucket_policy" "kb_access" {
  bucket = local.s3_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowBedrockKBAccess"
        Effect = "Allow"
        Principal = {
          Service = "bedrock.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          local.s3_bucket_arn,
          "${local.s3_bucket_arn}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:bedrock:${var.region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.knowledge_base,
    data.aws_s3_bucket.existing
  ]
}