# ---------------------------------------------
# S3 Bucket - Splink Search Input
#
# AP users write search requests here.
# Airflow reads and processes them.
# Nobody except Airflow can read submissions
# back — users cannot read each other's requests.
#
# No object lock: Airflow deletes processed files
# to track pipeline state.
# ---------------------------------------------

module "s3_bucket_splink_search_input" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6" # v5.14.1

  bucket        = local.splink_search_input_bucket_name
  force_destroy = false

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
          module.s3_bucket_splink_search_input.s3_bucket_arn,
          "${module.s3_bucket_splink_search_input.s3_bucket_arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid       = "RestrictToTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          module.s3_bucket_splink_search_input.s3_bucket_arn,
          "${module.s3_bucket_splink_search_input.s3_bucket_arn}/*"
        ]
        Condition = {
          NumericLessThan = { "aws:TLSVersion" = "1.2" }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${module.s3_bucket_splink_search_input.s3_bucket_arn}/*"
        Condition = {
          StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" }
        }
      },
      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${module.s3_bucket_splink_search_input.s3_bucket_arn}/*"
        Condition = {
          StringNotEquals = { "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.s3_kms_key.arn }
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
        Resource = module.s3_bucket_splink_search_input.s3_bucket_arn
      },
      {
        Sid      = "DenyReadObjects"
        Effect   = "Deny"
        Principal = "*"
        Action   = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource = "${module.s3_bucket_splink_search_input.s3_bucket_arn}/*"
        Condition = {
          ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_phase1_key_user_arns }
        }
      },
      {
        Sid       = "DenyListBucket"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:ListBucket"
        Resource  = module.s3_bucket_splink_search_input.s3_bucket_arn
        Condition = {
          ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_phase1_key_user_arns }
        }
      }
    ]
  })

  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_search_input_bucket_name}/"
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
    Name = local.splink_search_input_bucket_name
  })
}

resource "aws_s3_bucket_ownership_controls" "splink_search_input" {
  bucket = module.s3_bucket_splink_search_input.s3_bucket_id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudwatch_event_rule" "splink_search_input" {
  name        = "${local.splink_search_input_bucket_name}-event-rule"
  description = "Trigger on S3 Object Created events for ${local.splink_search_input_bucket_name}"

  event_pattern = jsonencode({
    source      = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = { name = [module.s3_bucket_splink_search_input.s3_bucket_id] }
    }
  })

  tags = merge(local.tags, {
    Name = "${local.splink_search_input_bucket_name}-event-rule"
  })
}

resource "aws_s3_bucket_notification" "splink_search_input" {
  bucket      = module.s3_bucket_splink_search_input.s3_bucket_id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "splink_search_input" {
  rule      = aws_cloudwatch_event_rule.splink_search_input.name
  target_id = "${local.splink_search_input_bucket_name}-event-target"
  arn       = aws_sns_topic.splink_bucket_alerting_topic.arn
}
