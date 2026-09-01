module "s3_bucket_search_output_test" {
  source                  = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6"
  bucket                  = local.splink_search_output_bucket_test_name
  force_destroy           = false
  versioning              = { enabled = true }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_lock_enabled     = true
  attach_policy           = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::${local.splink_search_output_bucket_test_name}", "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "RestrictToTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::${local.splink_search_output_bucket_test_name}", "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"]
        Condition = { NumericLessThan = { "aws:TLSVersion" = "1.2" } }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"
        Condition = { StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" } }
      },
      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"
        Condition = { StringNotEquals = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_kms_key.arn } }
      },
      {
        Sid       = "DenyBucketDeletion"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteBucket",
          "s3:PutBucketAcl",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketVersioning"
        ]
        Resource = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}"
      }
      ], [
      {
        Sid       = "DenyWritesForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_output_write_test_bucket_key_user_arns } }
      },
      {
        Sid       = "DenyReadsForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_output_read_test_bucket_key_user_arns } }
      },
      {
        Sid       = "DenyListingForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_search_output_bucket_test_name}"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_output_read_test_bucket_key_user_arns } }
      }
    ])
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
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 5110
      }
    }
  }
  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_search_output_bucket_test_name}/"
  }
  lifecycle_rule = [{
    id                                     = "expire-noncurrent-versions"
    enabled                                = true
    noncurrent_version_expiration          = { days = 5110 }
    abort_incomplete_multipart_upload_days = 7
  }]
  tags = merge(local.tags, { Name = local.splink_search_output_bucket_test_name })
}

resource "aws_s3_bucket_ownership_controls" "search_output_test" {
  bucket = module.s3_bucket_search_output_test.s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudwatch_event_rule" "s3_bucket_search_output_event_rule_test" {
  name        = "splink-search-output-bucket-event-rule-test"
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
          module.s3_bucket_search_output_test.s3_bucket_id
        ]
      }
    }
  })

  tags = merge(local.test_tags, {
    name = "splink-search-output-bucket-event-rule-test"
  })
}

resource "aws_s3_bucket_notification" "search_output_bucket_notification_test" {
  bucket      = module.s3_bucket_search_output_test.s3_bucket_id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "search_output_bucket_event_target_test" {
  rule      = aws_cloudwatch_event_rule.s3_bucket_search_output_event_rule_test.name
  target_id = "s3-event-target-test-search-output"
  arn       = aws_sns_topic.splink_test_bucket_alerting_topic.arn
}
