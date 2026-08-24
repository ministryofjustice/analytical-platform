#This is the file for S3 buckets module
module "s3_buckets" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6"

  bucket        = each.value
  force_destroy = false

  # Object Lock can be enabled later; S3 versioning is already enabled.
  # object_lock_enabled = true

  versioning = {
    enabled = true
  }

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  attach_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "RequireSSLRequests"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            "arn:aws:s3:::${each.value}",
            "arn:aws:s3:::${each.value}/*"
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
            "arn:aws:s3:::${each.value}",
            "arn:aws:s3:::${each.value}/*"
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
          Action    = "s3:PutObject"
          Resource  = "arn:aws:s3:::${each.value}/*"
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
          Action    = "s3:PutObject"
          Resource  = "arn:aws:s3:::${each.value}/*"
          Condition = {
            StringNotEquals = {
              "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_kms_key.arn
            }
          }
        }
      ],
      lookup(local.bucket_access_policy_statements, each.value, [])
    )
  })

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3_kms_key.arn
        sse_algorithm     = "aws:kms"
      }

      bucket_key_enabled = true
    }
  }

  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${each.value}/"
  }

  lifecycle_rule = [
    {
      id      = "expire-noncurrent-versions"
      enabled = true

      noncurrent_version_expiration = {
        days = 5110
      }
      abort_incomplete_multipart_upload_days = 7
    }
  ]

  tags = merge(local.tags, {
    Name = each.value
  })
}

resource "aws_s3_bucket_ownership_controls" "additional" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  bucket = module.s3_buckets[each.key].s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_metric" "additional" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  bucket = module.s3_buckets[each.key].s3_bucket_id
  name   = "EntireBucket"
}

resource "aws_cloudwatch_metric_alarm" "additional_bucket_size" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  alarm_name          = "${each.key}-size-alarm"
  alarm_description   = "Alert when S3 bucket exceeds 50GB"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 53687091200
  alarm_actions       = [aws_sns_topic.splink_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_buckets[each.key].s3_bucket_id
    StorageType = "StandardStorage"
  }
}

resource "aws_cloudwatch_metric_alarm" "additional_object_count" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  alarm_name          = "${each.key}-object-count-alarm"
  alarm_description   = "Alert when S3 bucket object count exceeds 100000"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = 100000
  alarm_actions       = [aws_sns_topic.splink_bucket_alerting_topic.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName  = module.s3_buckets[each.key].s3_bucket_id
    StorageType = "AllStorageTypes"
  }
}

resource "aws_cloudwatch_event_rule" "additional" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  name        = "${each.key}-event-rule"
  description = "Event rule to trigger on S3 Object Created events"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [module.s3_buckets[each.key].s3_bucket_id]
      }
    }
  })

  tags = merge(local.tags, {
    Name = "${each.key}-event-rule"
  })
}

resource "aws_s3_bucket_notification" "additional" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  bucket      = module.s3_buckets[each.key].s3_bucket_id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "additional" {
  for_each = toset([
    local.splink_search_input_bucket_name,
    local.splink_search_output_bucket_name,
    local.splink_source_input_bucket_name,
    local.splink_source_output_bucket_name,
    local.splink_audit_bucket_name
  ])

  rule      = aws_cloudwatch_event_rule.additional[each.key].name
  target_id = "${each.key}-event-target"
  arn       = aws_sns_topic.splink_bucket_alerting_topic.arn
}
