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
    resources = ["arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/add key-id here"]
  }
}

resource "aws_iam_policy" "vcms_crawler_policy" {
  name   = "vcms-crawler-policy"
  policy = data.aws_iam_policy_document.crawler_policy.json
}