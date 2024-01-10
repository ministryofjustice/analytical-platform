# setting up policy to be used with aws_sns_topic kms_master_key_id
data "aws_iam_policy_document" "kms_key" {
  statement {
    sid     = "EnableIAMUserPermissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.target.account_id}:root"]
    }
    resources = ["*"]
  }
  statement {
    sid    = "AllowSNStAlerts"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey*"
    ]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    resources = ["*"]
  }
}
