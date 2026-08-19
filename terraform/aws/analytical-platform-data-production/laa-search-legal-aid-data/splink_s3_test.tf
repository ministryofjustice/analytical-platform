# ---------------------------------------------
# S3 Bucket - Splink Test Output
# ---------------------------------------------

locals {
  splink_test_bucket_arn = "arn:aws:s3:::${local.splink_test_bucket_name}"
}

data "aws_iam_policy_document" "s3_test_kms_policy" {
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

      values = [
        "arn:aws:s3:::${local.splink_test_bucket_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    sid = "AllowAirflowAndNamedUserKeyUse"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/airflow-development-laa-si-access-test",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/airflow-development-laa-s3-ops",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/alpha_user_jamess-moj",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/alpha_user_dami-moj"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.splink_test_bucket_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "s3_test_kms_key" {
  description             = "S3 test bucket encryption key"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.s3_test_kms_policy.json
}

data "aws_iam_policy_document" "cloudwatch_sns_test_kms_policy" {
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
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
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
      test     = "StringEquals"
      variable = "kms:CallerAccount"
      values   = [data.aws_caller_identity.current.account_id]
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
        "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${local.splink_test_sns_topic_name}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["sns.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "cloudwatch_sns_test_alerts_key" {
  description         = "Test EventBridge and SNS notification encryption key"
  enable_key_rotation = true
  policy              = data.aws_iam_policy_document.cloudwatch_sns_test_kms_policy.json
}

resource "aws_sns_topic" "splink_test_bucket_alerting_topic" {
  name              = local.splink_test_sns_topic_name
  kms_master_key_id = aws_kms_key.cloudwatch_sns_test_alerts_key.id
}

data "aws_iam_policy_document" "splink_test_bucket_alerting_topic_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sns:Publish"
    ]

    resources = [
      aws_sns_topic.splink_test_bucket_alerting_topic.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values = [
        aws_cloudwatch_event_rule.s3_bucket_splink_event_rule_test.arn
      ]
    }
  }
}

resource "aws_sns_topic_policy" "splink_test_bucket_alerting_topic_policy" {
  arn = aws_sns_topic.splink_test_bucket_alerting_topic.arn

  policy = data.aws_iam_policy_document.splink_test_bucket_alerting_topic_policy.json
}

module "s3_bucket_splink_test" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6" # v5.14.1

  bucket = local.splink_test_bucket_name

  # TEST DIVERGENCE:
  # Object Lock is intentionally disabled for iterative integration testing.
  object_lock_enabled = false

  # TEST DIVERGENCE:
  # Allow Terraform to remove test objects and versions during teardown.
  force_destroy = true

  versioning = {
    enabled = true
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3_test_kms_key.arn
        sse_algorithm     = "aws:kms"
      }

      bucket_key_enabled = true
    }
  }

  attach_policy = true

  # TEST DIVERGENCE:
  # Production deletion and configuration-change denies are intentionally
  # omitted so the test resource can be iterated and removed safely.
  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          module.s3_bucket_splink_test.s3_bucket_arn,
          "${local.splink_test_bucket_arn}/*"
        ]

        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },

      {
        Sid       = "RestrictToTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          module.s3_bucket_splink_test.s3_bucket_arn,
          "${local.splink_test_bucket_arn}/*"
        ]

        Condition = {
          NumericLessThan = {
            "aws:TLSVersion" = "1.2"
          }
        }
      },

      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${local.splink_test_bucket_arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },

      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${local.splink_test_bucket_arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_test_kms_key.arn
          }
        }
      }
    ]
  })

  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_test_bucket_name}/"
  }

  lifecycle_rule = [
    {
      id                                     = "delete-noncurrent-versions-asap"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_expiration = {
        days = 3
      }
    },
    {
      id      = "expire-current-test-objects"
      enabled = true

      expiration = {
        expired_object_delete_marker = true
        days                         = 14
      }
    }
  ]

  tags = merge(
    local.test_tags,
    {
      Name = lower(format("s3-%s-test-splink-inbound-ap", local.application_name))
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "splink_test" {
  bucket = module.s3_bucket_splink_test.s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_metric" "splink_test_entire_bucket" {
  bucket = module.s3_bucket_splink_test.s3_bucket_id
  name   = "EntireBucket"
}

resource "aws_cloudwatch_metric_alarm" "s3_test_bucket_size_alarm" {
  alarm_name          = "splink-test-s3-bucket-size-alarm"
  alarm_description   = "Alert when test bucket exceeds 50GB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 53687091200 # 50GB
  alarm_actions       = [aws_sns_topic.splink_test_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_bucket_splink_test.s3_bucket_id
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_test_object_count_alarm" {
  alarm_name          = "splink-test-s3-object-count-alarm"
  alarm_description   = "Alert when test bucket object count exceeds 100000"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 100000
  alarm_actions       = [aws_sns_topic.splink_test_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_bucket_splink_test.s3_bucket_id
    StorageType = "AllStorageTypes"
  }
}

resource "aws_cloudwatch_event_rule" "s3_bucket_splink_event_rule_test" {
  name        = local.splink_test_event_rule_name
  description = "Event rule to trigger on test S3 Object Created events"

  event_pattern = jsonencode({
    source = [
      "aws.s3"
    ]

    detail-type = [
      "Object Created"
    ]

    detail = {
      bucket = {
        name = [
          module.s3_bucket_splink_test.s3_bucket_id
        ]
      }
    }
  })

  tags = merge(local.test_tags, {
    name = local.splink_test_event_rule_name
  })
}

resource "aws_s3_bucket_notification" "bucket_notification_test" {
  bucket      = module.s3_bucket_splink_test.s3_bucket_id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "bucket_event_target_test" {
  rule      = aws_cloudwatch_event_rule.s3_bucket_splink_event_rule_test.name
  target_id = "s3-event-target-test"
  arn       = aws_sns_topic.splink_test_bucket_alerting_topic.arn
}
