# =====================================================
# S3 Bucket Policy - Restricted Principal Access
# =====================================================

# Restrict bucket policy to specific IAM principals and services
data "aws_iam_policy_document" "splink_bucket_policy" {
  statement {
    sid    = "RequireSSLRequests"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      module.s3_bucket_splink.s3_bucket_arn,
      "${module.s3_bucket_splink.s3_bucket_arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "RestrictToTLSVersion12AndAbove"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      module.s3_bucket_splink.s3_bucket_arn,
      "${module.s3_bucket_splink.s3_bucket_arn}/*"
    ]
    condition {
      test     = "NumericLessThan"
      variable = "aws:TLSVersion"
      values   = ["1.2"]
    }
  }

  statement {
    sid    = "DenyBucketDeletion"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteBucket",
      "s3:PutBucketAcl",
      "s3:PutBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketVersioning"
    ]
    resources = [
      module.s3_bucket_splink.s3_bucket_arn
    ]
  }

  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3_bucket_splink.s3_bucket_arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  statement {
    sid    = "DenyWrongKMSKey"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:PutObject"]
    resources = [
      "${module.s3_bucket_splink.s3_bucket_arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.s3_kms_key.arn]
    }
  }

}
