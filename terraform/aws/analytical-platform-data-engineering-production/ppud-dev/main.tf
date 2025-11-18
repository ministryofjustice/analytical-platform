data "aws_iam_policy_document" "ppud_dev" {
  statement {
    sid    = "Set-permissions-for-objects"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_ids["ppud-development"]}:role/service-role/iam_role_s3_bucket_moj_database_source_dev_test"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-data-engineering-production-ppud-dev/*"]
  }
  statement {
    sid    = "Set-permissions-on-bucket"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_ids["ppud-development"]}:role/service-role/iam_role_s3_bucket_moj_database_source_dev_test"]
    }
    actions = [
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = ["arn:aws:s3:::mojap-data-engineering-production-ppud-dev"]
  }
}

# trivy:ignore:avd-aws-0132: Skipping because replicating existing bucket that does not encrypt data with a customer managed key
# trivy:ignore:avd-aws-0088: Skipping because has server side encryption
# trivy:ignore:avd-aws-0089: Skipping because access logging is managed externally.
module "ppud_dev" {
  # checkov:skip=CKV_TF_1: Module registry does not support commit hashes for versions
  # checkov:skip=CKV_TF_2: Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket              = "mojap-data-engineering-production-ppud-dev"
  force_destroy       = false
  object_lock_enabled = true
  object_lock_configuration = {
    rule = {
      default_retention = {
        mode = "GOVERNANCE"
        days = 30
      }
    }
    versioning = {
      enabled = true
    }
    server_side_encryption_configuration = {
      rule = {
        bucket_key_enabled = false
        apply_server_side_encryption_by_default = {
          sse_algorithm = "AES256"
        }
      }
    }
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
  attach_policy = true
  policy        = sensitive(data.aws_iam_policy_document.ppud_dev.json)

  tags = var.tags
}
