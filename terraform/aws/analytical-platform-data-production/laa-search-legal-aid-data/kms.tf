data "aws_iam_policy_document" "s3_kms_policy" {

  statement {
    sid = "AllowAccountRootAdmin"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:ListAliases",
      "kms:ListResourceTags",
      "kms:PutKeyPolicy",
      "kms:EnableKeyRotation",
      "kms:DisableKeyRotation",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = [
      aws_kms_key.s3_kms_key.arn
    ]
  }


  statement {
    sid = "AllowS3UseOfKey"

    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:GenerateDataKeyWithoutPlaintext",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.s3_kms_key.arn
    ]

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
        "s3.${data.aws_region.current.name}.amazonaws.com"
      ]
    }
  }
}