# checkov:skip=CKV2_AWS_62: Skipping because event notifications are not applicable for this bucket.
# checkov:skip=CKV_AWS_18: Skipping because access logging is managed externally.
# checkov:skip=CKV_AWS_145: Skipping because KMS encryption is handled at the account level.
# checkov:skip=CKV2_AWS_61: Skipping because a lifecycle configuration is not required.
# checkov:skip=CKV_AWS_144: Skipping because cross-region replication is not needed.

#trivy:ignore:avd-aws-0132: Skipping because replicating existing bucket that does not encrypt data with a customer managed key
#trivy:ignore:avd-aws-0088: Skipping because has server side encryption
#trivy:ignore:avd-aws-0089: Skipping because access logging is managed externally.
module "ppud_preprod" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.4.0"

  bucket              = "mojap-data-engineering-production-ppud-preprod"
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

  tags = var.tags
}
