data "aws_iam_policy_document" "alpha_vcms_data_crawler_policy" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::alpha-vcms-data/*"]
  }
  statement {
    sid       = "AllowKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_key.rds_s3_export.arn]
  }
}

resource "aws_iam_policy" "alpha_vcms_data_crawler" {
  name   = "alpha-vcms-data-crawler"
  policy = data.aws_iam_policy_document.alpha_vcms_data_crawler_policy.json
}
