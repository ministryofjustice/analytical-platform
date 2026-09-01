# The following policy is S3 KMS policy for Production Buckets
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
      type        = "Service"
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
      variable = "kms:EncryptionContext:aws:s3:arn"

      values = concat(
        ["arn:aws:s3:::${local.splink_bucket_name}"],
        [
          "arn:aws:s3:::${local.splink_search_input_bucket_name}",
          "arn:aws:s3:::${local.splink_search_output_bucket_name}",
          "arn:aws:s3:::${local.splink_source_bucket_name}",
          "arn:aws:s3:::${local.splink_source_input_bucket_name}",
          "arn:aws:s3:::${local.splink_source_output_bucket_name}",
          "arn:aws:s3:::${local.splink_audit_bucket_name}"
        ]
      )
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # S3 Input-Read
  statement {
    sid = "AllowSplinkS3InputReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_input_read_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # S3 Input-Write
  statement {
    sid = "AllowSplinkS3InputWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_input_write_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 OUTPUT - READ
  statement {
    sid = "AllowSplinkS3OutputReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_output_read_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 OUTPUT - WRITE
  statement {
    sid = "AllowSplinkS3OutputWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_output_write_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 AUDIT - READ
  statement {
    sid = "AllowSplinkS3AuditReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_audit_read_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 AUDIT - WRITE
  statement {
    sid = "AllowSplinkS3AuditWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_audit_write_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 SOURCE - READ
  statement {
    sid = "AllowSplinkS3SourceReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_source_read_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 SOURCE - WRITE
  statement {
    sid = "AllowSplinkS3SourceWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_source_write_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    sid = "AllowAirflowKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

# Cloudwatch, SNS, KMS policy for Production
data "aws_iam_policy_document" "cloudwatch_sns_kms_policy" {
  #checkov:skip=CKV_AWS_111 KMS key administration permissions are required for the account root principal.
  #checkov:skip=CKV_AWS_109 KMS key policies require key administration actions.
  #checkov:skip=CKV_AWS_356 AWS KMS key policies require Resource="*" and cannot reference the key ARN.
  statement {
    sid = "AllowRootAccountAdmin"

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
    sid = "AllowEventBridgeUseOfKey"

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo"
    ]

    resources = ["*"]

    condition {
      test = "StringEquals"

      variable = "kms:CallerAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }

  statement {
    sid = "AllowSNSUseOfKey"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
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
      variable = "kms:EncryptionContext:aws:sns:topicArn"

      values = [
        "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:splink-*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

# The following resources belongs to Production
resource "aws_kms_key" "s3_kms_key" {
  description             = "S3 bucket encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_policy.json
}

resource "aws_kms_key" "cloudwatch_sns_alerts_key" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_sns_kms_policy.json
}

# The following S3 KMS policy is for Test buckets
data "aws_iam_policy_document" "s3_kms_policy_test" {
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
      type        = "Service"
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
      variable = "kms:EncryptionContext:aws:s3:arn"

      values = concat(
        ["arn:aws:s3:::${local.splink_test_bucket_name}"],
        [
          "arn:aws:s3:::${local.splink_search_input_bucket_test_name}",
          "arn:aws:s3:::${local.splink_search_output_bucket_test_name}",
          "arn:aws:s3:::${local.splink_source_bucket_test_name}",
          "arn:aws:s3:::${local.splink_source_input_bucket_test_name}",
          "arn:aws:s3:::${local.splink_source_output_bucket_test_name}",
          "arn:aws:s3:::${local.splink_audit_bucket_test_name}"
        ]
      )
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # S3 Input-Read
  statement {
    sid = "AllowSplinkS3InputReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_input_read_test_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # S3 Input-Write
  statement {
    sid = "AllowSplinkS3InputWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_input_write_test_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 OUTPUT - READ
  statement {
    sid = "AllowSplinkS3OutputReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_output_read_test_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 OUTPUT - WRITE
  statement {
    sid = "AllowSplinkS3OutputWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_output_write_test_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 AUDIT - READ
  statement {
    sid = "AllowSplinkS3AuditReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_audit_read_test_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 AUDIT - WRITE
  statement {
    sid = "AllowSplinkS3AuditWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_audit_write_test_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 SOURCE - READ
  statement {
    sid = "AllowSplinkS3SourceReadKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_source_read_test_bucket_key_user_arns
    }

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
  # SPLINK S3 SOURCE - WRITE
  statement {
    sid = "AllowSplinkS3SourceWriteKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_source_write_test_bucket_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    sid = "AllowAirflowKeyUse"

    principals {
      type        = "AWS"
      identifiers = local.splink_s3_key_user_arns
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_sns_kms_policy_test" {
  #checkov:skip=CKV_AWS_111 KMS key administration permissions are required for the account root principal.
  #checkov:skip=CKV_AWS_109 KMS key policies require key administration actions.
  #checkov:skip=CKV_AWS_356 AWS KMS key policies require Resource="*" and cannot reference the key ARN.
  statement {
    sid = "AllowRootAccountAdmin"

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
    sid = "AllowEventBridgeUseOfKey"

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:ReEncryptFrom",
      "kms:ReEncryptTo"
    ]

    resources = ["*"]

    condition {
      test = "StringEquals"

      variable = "kms:CallerAccount"

      values = [
        data.aws_caller_identity.current.account_id
      ]
    }
  }

  statement {
    sid = "AllowSNSUseOfKey"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
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
      variable = "kms:EncryptionContext:aws:sns:topicArn"

      values = [
        "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:splink-*"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

# The following resources belongs to Test
resource "aws_kms_key" "s3_kms_key_test" {
  description             = "S3 bucket encryption key for Test Bucket"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_kms_policy_test.json
}

resource "aws_kms_key" "cloudwatch_sns_alerts_key_test" {
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_sns_kms_policy_test.json
}
