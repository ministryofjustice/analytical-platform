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
}

module "coat_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.2.0"

  bucket = local.bucket_name

  force_destroy = true

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
