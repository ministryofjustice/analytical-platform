data "aws_iam_policy_document" "s3_kms_policy" {
  #checkov:skip=CKV_AWS_111 KMS key administration permissions are required for the account root principal.
  #checkov:skip=CKV_AWS_109 KMS key policies require key administration actions.
  #checkov:skip=CKV_AWS_356 AWS KMS key policies require Resource="*" and cannot reference the key ARN.
  statement {
    sid = "AllowAccountRootAdmin"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowS3UseOfKey"

    principals {
      type = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "s3_kms_key" {
  description         = "S3 bucket encryption key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.s3_kms_policy.json
}

data "aws_iam_policy_document" "cloudwatch_sns_kms_policy" {

  statement {
    sid = "AllowRootAccountAdmin"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = ["*"]
  }

  statement {
    sid = "AllowSNSUseOfKey"

    principals {
      type = "Service"
      identifiers = [
        "sns.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:CallerAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "sns.${data.aws_region.current.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_kms_key" "cloudwatch_sns_alerts_key" {
  description             = "KMS Key for CloudWatch SNS Alerts Encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = data.aws_iam_policy_document.cloudwatch_sns_kms_policy.json

  tags = merge(local.tags,
    {
      Name = lower(format("%s-%s-cloudwatch-sns-alerts-kms-key", local.application_name, local.environment))
    }
  )
}

resource "aws_kms_alias" "cloudwatch_sns_alerts_key_alias" {
  name          = "alias/cloudwatch-sns-alerts-key"
  target_key_id = aws_kms_key.cloudwatch_sns_alerts_key.id
}
