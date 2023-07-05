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
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:CreateGrant",
      "kms:DescribeKey",
      "kms:RetireGrant"
    ]
    resources = [resource.aws_kms_key.rds_s3_export.arn]
  }
}

resource "aws_iam_policy" "rds_s3_export" {
  name   = "rds-s3-export"
  policy = data.aws_iam_policy_document.export_policy.json
}
