# =====================================================
# CloudTrail Configuration - S3 Data Events Logging
# =====================================================

#checkov:skip=CKV_AWS_144:Cross-region replication is not required for this regional test data platform.
resource "aws_s3_bucket" "cloudtrail_logs_bucket" {
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required as it should be in eu-west-2 only
  bucket = "${local.splink_bucket_name}-cloudtrail-logs"

  tags = merge(
    local.tags,
    {
      Name = "cloudtrail-logs-${local.application_name}"
    }
  )
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail_key.arn
      sse_algorithm     = "aws:kms"
    }

    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_logging" "cloudtrail_logs" {
  bucket        = aws_s3_bucket.cloudtrail_logs_bucket.id
  target_bucket = local.logging_bucket_name
  target_prefix = "s3access/${aws_s3_bucket.cloudtrail_logs_bucket.id}/"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id

  rule {
    id     = "expire-cloudtrail-logs"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_notification" "cloudtrail_logs" {
  bucket      = aws_s3_bucket.cloudtrail_logs_bucket.id
  eventbridge = true
}

# CloudTrail bucket policy
data "aws_iam_policy_document" "cloudtrail_logs_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [aws_s3_bucket.cloudtrail_logs_bucket.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.cloudtrail_logs_bucket.arn}/cloudtrail-logs/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket.id
  policy = data.aws_iam_policy_document.cloudtrail_logs_policy.json
}

# CloudTrail trail for S3 data events
resource "aws_cloudtrail" "splink_s3_trail" {
  #checkov:skip=CKV_AWS_67:This trail is intentionally scoped to eu-west-2 for the regional platform.
  name                          = "splink-s3-data-events-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs_bucket.id
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cloudtrail_key.arn
  sns_topic_name                = aws_sns_topic.splink_bucket_alerting_topic.name
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch_role.arn
  depends_on                    = [aws_s3_bucket_policy.cloudtrail_logs]

  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${module.s3_bucket_splink.s3_bucket_arn}/*"]
    }

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${module.s3_bucket_splink_test.s3_bucket_arn}/*"]
    }
  }

  tags = merge(
    local.tags,
    {
      Name = "splink-s3-trail"
    }
  )
}

# KMS key for CloudTrail logs encryption
data "aws_iam_policy_document" "cloudtrail_kms_policy" {
  statement {
    #checkov:skip=CKV_AWS_109:KMS key administration requires account-root permissions.
    #checkov:skip=CKV_AWS_111:KMS key administration requires account-root permissions.
    #checkov:skip=CKV_AWS_356:KMS key policies require Resource="*".
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
      "kms:UntagResource"
    ]

    resources = ["*"]
  }

  statement {
    #checkov:skip=CKV_AWS_356:KMS key policies require Resource="*".
    sid = "AllowCloudTrailUseOfKey"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs_bucket.id}/cloudtrail-logs/*"
      ]
    }
  }

  statement {
    #checkov:skip=CKV_AWS_356:KMS key policies require Resource="*".
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
      values   = ["arn:aws:s3:::${local.splink_bucket_name}-cloudtrail-logs"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["s3.${data.aws_region.current.region}.amazonaws.com"]
    }
  }

  statement {
    #checkov:skip=CKV_AWS_356:KMS key policies require Resource="*".
    sid = "AllowCloudWatchLogsUseOfKey"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
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
      test     = "ArnEquals"
      variable = "kms:EncryptionContext:aws:logs:arn"
      values   = ["arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/cloudtrail/splink-s3-events"]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

resource "aws_kms_key" "cloudtrail_key" {
  description             = "KMS key for CloudTrail S3 data events encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30
  policy                  = data.aws_iam_policy_document.cloudtrail_kms_policy.json

  tags = merge(
    local.tags,
    {
      Name = "cloudtrail-key"
    }
  )
}

resource "aws_kms_alias" "cloudtrail_key_alias" {
  name          = "alias/splink-cloudtrail-key"
  target_key_id = aws_kms_key.cloudtrail_key.key_id
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "/aws/cloudtrail/splink-s3-events"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudtrail_key.arn

  tags = merge(
    local.tags,
    {
      Name = "splink-cloudtrail-logs"
    }
  )
}

# IAM role for CloudTrail CloudWatch Logs
data "aws_iam_policy_document" "cloudtrail_cloudwatch_trust" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudtrail_cloudwatch_role" {
  name               = "cloudtrail-cloudwatch-logs-role"
  assume_role_policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_trust.json

  tags = merge(local.tags, {
    Name = "cloudtrail-cloudwatch-role"
  })
}

data "aws_iam_policy_document" "cloudtrail_cloudwatch_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch_policy" {
  name   = "cloudtrail-cloudwatch-logs-policy"
  role   = aws_iam_role.cloudtrail_cloudwatch_role.id
  policy = data.aws_iam_policy_document.cloudtrail_cloudwatch_policy.json
}
