# ---------------------------------------------
# S3 Bucket - Splink Output
# ---------------------------------------------

module "s3_bucket_splink" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6" # v5.14.1

  bucket              = local.splink_bucket_name
  object_lock_enabled = true
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
        kms_master_key_id = aws_kms_key.s3_kms_key.arn
        sse_algorithm     = "aws:kms"
      }

      bucket_key_enabled = true
    }
  }

  attach_policy = true

  policy = data.aws_iam_policy_document.splink_bucket_policy.json

  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_bucket_name}/"
  }

  lifecycle_rule = [
    {
      id                                     = "delete-noncurrent-versions-asap"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7

      noncurrent_version_expiration = {
        days = 3
      }
    }
  ]

  tags = merge(
    local.tags,
    {
      Name = lower(format("s3-%s-splink-inbound-ap", local.application_name))
    }
  )
}

resource "aws_s3_bucket_ownership_controls" "splink" {
  bucket = module.s3_bucket_splink.s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_metric" "splink_entire_bucket" {
  bucket = module.s3_bucket_splink.s3_bucket_id
  name   = "EntireBucket"
}

resource "aws_cloudwatch_metric_alarm" "s3_bucket_size_alarm" {
  alarm_name          = "splink-s3-bucket-size-alarm"
  alarm_description   = "Alert when S3 bucket exceeds 100GB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 107374182400 # 100GB in bytes
  alarm_actions       = [aws_sns_topic.splink_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_bucket_splink.s3_bucket_id
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "s3_object_count_alarm" {
  alarm_name          = "splink-s3-object-count-alarm"
  alarm_description   = "Alert when S3 object count exceeds 1 million"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 1000000
  alarm_actions       = [aws_sns_topic.splink_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_bucket_splink.s3_bucket_id
    StorageType = "AllStorageTypes"
  }
}

resource "aws_cloudwatch_event_rule" "s3_bucket_splink_event_rule" {
  name        = "splink-bucket-event-rule"
  description = "Event rule to trigger on S3 Object Created events"

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
          module.s3_bucket_splink.s3_bucket_id
        ]
      }
    }
  })

  tags = merge(local.tags, {
    name = "splink-bucket-event-rule"
  })
}


resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = module.s3_bucket_splink.s3_bucket_id
  eventbridge = true
}


resource "aws_cloudwatch_event_target" "bucket_event_target" {
  rule      = aws_cloudwatch_event_rule.s3_bucket_splink_event_rule.name
  target_id = "s3-event-target"
  arn       = aws_sns_topic.splink_bucket_alerting_topic.arn
}
