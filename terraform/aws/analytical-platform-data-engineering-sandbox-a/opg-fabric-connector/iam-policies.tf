data "aws_iam_policy_document" "opg_fabric_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.opg_fabric_connector.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts.windows.net/${local.tenant_id}/:aud"
      values   = ["https://analysis.windows.net/powerbi/connector/AmazonS3"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts.windows.net/${local.tenant_id}/:sub"
      values   = [local.object_id]
    }
  }
}
