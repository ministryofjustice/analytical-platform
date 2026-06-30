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

# -----------------------------------------------------------------------------
# IAM Policy for Federated Queries (Aurora Secret Access)
# -----------------------------------------------------------------------------
resource "aws_iam_policy" "aurora_federated_secret" {
  count = var.aurora_federated_secret_arn != null ? 1 : 0

  name        = "${var.project_name}-${var.environment}-aurora-federated-secret"
  description = "Enables Redshift to access Aurora credentials for federated queries"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AccessSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = [var.aurora_federated_secret_arn]
      },
      {
        Sid    = "ListSecrets"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Sid    = "DecryptSecretKey"
        Effect = "Allow"
        Action = ["kms:Decrypt"]
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aurora_federated_secret" {
  count = var.aurora_federated_secret_arn != null ? 1 : 0

  role       = aws_iam_role.redshift.name
  policy_arn = aws_iam_policy.aurora_federated_secret[0].arn
}
