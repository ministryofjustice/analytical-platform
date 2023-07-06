data "aws_iam_policy_document" "crawler_policy" {
  statement {
    sid    = "AllowS3"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-vcms-data/*"
    ]
  }
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt"
    ]
    resources = ["${data.aws_kms_key.by_alias.arn}"]
  }
}

resource "aws_iam_policy" "vcms_crawler_policy" {
  name   = "vcms-crawler-policy"
  policy = data.aws_iam_policy_document.crawler_policy.json
}