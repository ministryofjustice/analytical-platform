data "aws_iam_policy_document" "entra_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.entra.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts.windows.net/<your-tenant-id>/:aud"
      values   = ["https://analysis.windows.net/powerbi/connector/AmazonS3"]
    }
  }
}