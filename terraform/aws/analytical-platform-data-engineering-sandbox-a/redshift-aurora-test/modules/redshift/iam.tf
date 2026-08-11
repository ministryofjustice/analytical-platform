# -----------------------------------------------------------------------------
# IAM Role for Redshift Serverless
# -----------------------------------------------------------------------------
resource "aws_iam_role" "redshift" {
  name        = "${var.project_name}-${var.environment}-redshift-role"
  description = "Service role for Redshift Serverless"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "redshift.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach managed policy for basic Redshift operations
resource "aws_iam_role_policy_attachment" "redshift_data_full_access" {
  role       = aws_iam_role.redshift.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftDataFullAccess"
}
