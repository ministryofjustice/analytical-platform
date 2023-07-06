data "aws_iam_policy_document" "export_kms_key" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "rds_s3_export" {
  policy              = data.aws_iam_policy_document.export_kms_key.json
  enable_key_rotation = true
}
