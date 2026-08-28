module "s3_bucket_source_test" {
  source                  = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=97bb13eff35489bd38993487c3d04c5b6d024cb6"
  bucket                  = local.splink_source_bucket_test_name
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
        Resource  = ["arn:aws:s3:::${local.splink_source_bucket_test_name}", "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"]
        Condition = { Bool = { "aws:SecureTransport" = "false" } }
      },
      {
        Sid       = "RestrictToTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = ["arn:aws:s3:::${local.splink_source_bucket_test_name}", "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"]
        Condition = { NumericLessThan = { "aws:TLSVersion" = "1.2" } }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"
        Condition = { StringNotEquals = { "s3:x-amz-server-side-encryption" = "aws:kms" } }
      },
      {
        Sid       = "DenyWrongKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"
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
        Resource = "arn:aws:s3:::${local.splink_source_bucket_test_name}"
      }
      ], [
      {
        Sid       = "DenyWritesForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:PutObject", "s3:DeleteObject", "s3:DeleteObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_write_bucket_key_user_arns } }
      },
      {
        Sid       = "DenyReadsForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:GetObject", "s3:GetObjectVersion"]
        Resource  = "arn:aws:s3:::${local.splink_source_bucket_test_name}/*"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_read_bucket_key_user_arns } }
      },
      {
        Sid       = "DenyListingForUnauthorisedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = ["s3:ListBucket"]
        Resource  = "arn:aws:s3:::${local.splink_source_bucket_test_name}"
        Condition = { ArnNotEquals = { "aws:PrincipalArn" = local.splink_s3_source_read_bucket_key_user_arns } }
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
    target_prefix = "s3access/${local.splink_source_bucket_test_name}/"
  }

  lifecycle_rule = [{
    id                                     = "expire-noncurrent-versions"
    enabled                                = true
    noncurrent_version_expiration          = { days = 90 }
    abort_incomplete_multipart_upload_days = 7
  }]

  tags = merge(local.tags, { Name = local.splink_source_bucket_test_name })
}
