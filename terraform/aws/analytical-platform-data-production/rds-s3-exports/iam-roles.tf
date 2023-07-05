data "aws_iam_policy_document" "export_policy" {
  statement {
    sid    = "ExportPolicy"
    effect = "Allow"
    actions = [
      "s3:PutObject*",
      "s3:ListBucket",
      "s3:GetObject*",
      "s3:DeleteObject*",
      "s3:GetBucketLocation"
    ]
    resources = [
      "arn:aws:s3:::alpha-vcms-data",
      "arn:aws:s3:::alpha-vcms-data/*"

    ]
  }
}

resource "aws_iam_policy" "rds_s3_export_policy" {
  name   = "rds_s3_export_policy"
  policy = data.aws_iam_policy_document.export_policy.json
}

resource "aws_iam_role" "rds_s3_export_role" {
  name = "rds_s3_export_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_s3_export" {
  name       = "rds_s3_export_attachment"
  role       = aws_iam_role.rds_s3_export_role.name
  policy_arn = aws_iam_policy.rds_s3_export_policy.arn
}
