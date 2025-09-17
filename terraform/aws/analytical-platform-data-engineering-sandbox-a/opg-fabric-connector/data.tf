data "aws_iam_policy_document" "bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.opg_entra_fabric.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.opg_entra_fabric.arn}/*"]
  }
}

resource "aws_iam_role_policy" "entra_bucket_access" {
  name   = "entra-bucket-access"
  role   = aws_iam_role.entra_role.id
  policy = data.aws_iam_policy_document.bucket_access.json
}