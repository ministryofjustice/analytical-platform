# ---------------------------------------------
# S3 Bucket - Splink Output
# ---------------------------------------------

module "s3_bucket_splink" {
  source             = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_name        = local.splink_bucket_name
  versioning_enabled = true

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  bucket_policy = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bucket_splink.bucket.arn,
          "${module.s3_bucket_splink.bucket.arn}/*"
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
          module.s3_bucket_splink.bucket.arn,
          "${module.s3_bucket_splink.bucket.arn}/*"
        ]
        Condition = {
          NumericLessThan = {
            "aws:TLSVersion" = "1.2"
          }
        }
      },
      {
        Sid    = "DenyBucketDeletion"
        Effect = "Deny"

        Principal = "*"

        Action = [
          "s3:DeleteBucket",
          "s3:PutBucketPolicy",
          "s3:PutBucketAcl",
          "s3:PutEncryptionConfiguration",
          "s3:PutBucketVersioning"
        ]

        Resource = [
          module.s3_bucket_splink.bucket.arn
        ]
      },
      {
        Sid = "DenyUnencryptedObjectUploads"

        Effect = "Deny"

        Principal = "*"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${module.s3_bucket_splink.bucket.arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid = "DenyWrongKMSKey"

        Effect = "Deny"

        Principal = "*"

        Action = [
          "s3:PutObject"
        ]

        Resource = [
          "${module.s3_bucket_splink.bucket.arn}/*"
        ]

        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_kms_key.arn
          }
        }
      },
      {
        Sid = "DenyObjectWritesExceptSplink"

        Effect = "Deny"

        Principal = "*"

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
          "${module.s3_bucket_splink.bucket.arn}/*"
        ]
      }
    ]
  })]

  log_bucket = local.logging_bucket_name
  log_prefix = "s3access/${local.splink_bucket_name}"

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = aws_kms_key.s3_kms_key.arn
        sse_algorithm     = "aws:kms"
      }

      bucket_key_enabled = true
    }
  }

  # Refer to the below section "Replication" before enabling replication
  replication_enabled = false
  # Below three variables and providers configuration are only relevant if 'replication_enabled' is set to true
  replication_region = "eu-west-2"
  # replication_role_arn = module.s3-bucket-replication-role.role.arn
  providers = {
    # Here we use the default provider Region for replication. Destination buckets can be within the same Region as the
    # source bucket. On the other hand, if you need to enable cross-region replication, please contact the Modernisation
    # Platform team to add a new provider for the additional Region.
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      id      = "delete-noncurrent-versions-asap"
      enabled = "Enabled"
      prefix  = ""

      noncurrent_version_expiration = {
        days = 3
      }
    },
  ]

  tags = merge(local.tags,
    { Name = lower(format("s3-%s-splink-inbound-ap", local.application_name)) }
  )
}

resource "aws_s3_bucket_ownership_controls" "splink" {
  bucket = module.s3_bucket_splink.bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudwatch_event_rule" "bucket_event_rule" {
  name        = "splink-bucket-event-rule"
  description = "Event rule to trigger on S3 Object Created events for the Search bucket"
  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [module.s3_bucket_splink.bucket.id]
      }
    }
  })
  tags = merge(local.tags, { name = "splink-bucket-event-rule" })
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = module.s3_bucket_splink.bucket.id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "bucket_event_target" {
  rule      = aws_cloudwatch_event_rule.bucket_event_rule.name
  target_id = "s3-event-target"
  arn       = aws_sns_topic.s3_topic.arn
}
