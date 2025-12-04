data "aws_iam_policy_document" "coat_bucket_policies" {
  for_each = local.buckets

  statement {
    sid    = "AllowReplicationRole"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [each.value.source_replication_role]
    }
    actions = [
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ReplicateTags"
    ]
    resources = ["arn:aws:s3:::${each.value.bucket_name}/*"]
  }
}

moved {
  from = module.coat_s3
  to   = module.coat_s3_buckets["coat_cur_reports_v2_hourly"]
}

#trivy:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "coat_s3_buckets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.buckets

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket = each.value.bucket_name

  force_destroy = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.coat_bucket_policies[each.key].json

  server_side_encryption_configuration = {
    bucket_key_enabled = true
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.coat_kms_keys[each.key].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
