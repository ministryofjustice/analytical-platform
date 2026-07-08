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

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"

        Resource = [
          module.s3_bucket_splink.s3_bucket_arn,
          "${module.s3_bucket_splink.s3_bucket_arn}/*"
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
          module.s3_bucket_splink.s3_bucket_arn,
          "${module.s3_bucket_splink.s3_bucket_arn}/*"
        ]

        Condition = {
          NumericLessThan = {
            "aws:TLSVersion" = "1.2"
          }
        }
      },

      {
        Sid       = "DenyBucketDeletion"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:DeleteBucket",
          "s3:PutBucketAcl",
          "s3:PutBucketPolicy",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketVersioning"
        ]

        Resource = [
          module.s3_bucket_splink.s3_bucket_arn
        ]
      },

      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${module.s3_bucket_splink.s3_bucket_arn}/*"
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
          "${module.s3_bucket_splink.s3_bucket_arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_kms_key.arn
          }
        }
      },

      {
        Sid    = "AllowSplinkWriterOnly"
        Effect = "Deny"

        NotPrincipal = {
          AWS = [
            aws_iam_role.splink_writer.arn
          ]
        }

        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "${module.s3_bucket_splink.s3_bucket_arn}/*"
        ]
      }
    ]
  })

  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_bucket_name}/"
  }

  lifecycle_rule = [
    {
      id      = "delete-noncurrent-versions-asap"
      enabled = true

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

resource "aws_cloudwatch_event_rule" "bucket_event_rule" {
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
  rule      = aws_cloudwatch_event_rule.bucket_event_rule.name
  target_id = "s3-event-target"
  arn       = aws_sns_topic.s3_topic.arn
}
