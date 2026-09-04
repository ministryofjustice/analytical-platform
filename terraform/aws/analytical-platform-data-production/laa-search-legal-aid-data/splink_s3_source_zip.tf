# The following bucket is laa-splink-source-zip.
# This bucket shouldn't have object Lock
module "s3_bucket_source_zip" {
  source                  = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6"
  bucket                  = local.splink_source_zip_bucket_name
  force_destroy           = false
  versioning              = { enabled = true }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  attach_policy           = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "RequireSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::${local.splink_source_zip_bucket_name}", "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "RestrictToTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::${local.splink_source_zip_bucket_name}", "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"]
        Condition = { NumericLessThan = { "aws:TLSVersion" = "1.2" } }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"
        Condition = { StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" } }
      },
      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"
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
        Resource = "arn:aws:s3:::${local.splink_source_zip_bucket_name}"
      },
      ], [
      {
        Sid       = "DenyReadsForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_zip_read_bucket_key_user_arns } }
      },
      {
        Sid       = "DenyListingForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_zip_read_bucket_key_user_arns } }
      },
      {
        # PutObject is restricted to a placeholder until the LAA user role is created —
        # replace alpha_user_jamess-moj with the LAA user role ARN when available
        Sid       = "DenyWritesForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject"]
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_zip_write_bucket_key_user_arns } }
      },
      {
        # Explicit Deny on DeleteObjectVersion
        Sid       = "DenyObjectDeletion"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_zip_bucket_name}/*"
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
  logging = {
    target_bucket = local.logging_bucket_name
    target_prefix = "s3access/${local.splink_source_zip_bucket_name}/"
  }
  lifecycle_rule = [{
    id                                     = "expire-noncurrent-versions"
    enabled                                = true
    noncurrent_version_expiration          = { days = 5110 }
    abort_incomplete_multipart_upload_days = 7
  }]
  tags = merge(local.tags, { Name = local.splink_source_zip_bucket_name })
}

resource "aws_s3_bucket_ownership_controls" "source_zip_input_test" {
  bucket = module.s3_bucket_source_zip.s3_bucket_id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_cloudwatch_event_rule" "s3_bucket_source_zip_event_rule_prod" {
  name        = "splink-source-zip-bucket-event-rule-prod"
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
          module.s3_bucket_source_zip.s3_bucket_id
        ]
      }
    }
  })

  tags = merge(local.test_tags, {
    name = "splink-source-zip-bucket-event-rule-prod"
  })
}

resource "aws_s3_bucket_notification" "source_zip_bucket_notification_prod" {
  bucket      = module.s3_bucket_source_zip.s3_bucket_id
  eventbridge = true
}

resource "aws_cloudwatch_event_target" "source_zip_bucket_event_target_prod" {
  rule      = aws_cloudwatch_event_rule.s3_bucket_source_zip_event_rule_prod.name
  target_id = "s3-event-target-test-source-zip"
  arn       = aws_sns_topic.splink_bucket_alerting_topic.arn
}
