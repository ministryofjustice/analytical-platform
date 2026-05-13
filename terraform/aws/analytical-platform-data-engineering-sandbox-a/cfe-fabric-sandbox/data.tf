data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_iam_policy_document" "bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.cfe_fabric_store.s3_bucket_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${module.cfe_fabric_store.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "entra_bucket_access" {
  name   = "entra-bucket-access"
  role   = aws_iam_role.cfe_fabric_access.id
  policy = data.aws_iam_policy_document.bucket_access.json
}
