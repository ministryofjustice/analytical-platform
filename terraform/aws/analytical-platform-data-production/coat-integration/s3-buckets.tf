data "aws_iam_policy_document" "coat_bucket_policy" {
  statement {
    sid    = "AllowReplicationRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [local.source_replication_role]
    }
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags"
    ]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }

  statement {
    sid    = "DataSyncCreateS3LocationAndTaskAccess"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::684969100054:role/coat-datasync-iam-role"] #TODO: Change this in the root account implementation
    }

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging",
    ]

    resources = [
      "arn:aws:s3:::${local.bucket_name}",
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }
}

#trivy:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "coat_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.7.0"

  bucket = local.bucket_name

  force_destroy = true

  acl              = "private"             # Ensures no public ACLs are applied
  object_ownership = "BucketOwnerEnforced" # Disables ACLs

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.coat_bucket_policy.json

  server_side_encryption_configuration = {
    bucket_key_enabled = true
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.coat_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
