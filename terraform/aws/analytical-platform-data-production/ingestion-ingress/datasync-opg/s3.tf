data "aws_iam_policy_document" "datasync_opg_ingress_bucket_policy" {

  for_each = local.analytical_platform_ingestion_environments

  statement {
    sid    = "DataSyncOPGReplicationPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-ingestion-${each.key}"]}:role/datasync-opg-ingress-${each.key}-replication"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-data-production-datasync-opg-ingress-${each.key}/*"]
  }
}

#tfsec:ignore:AVD-AWS-0088:Bucket is encrypted with CMK KMS, but not detected by Trivy
#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
#tfsec:ignore:AVD-AWS-0132:Bucket is encrypted with CMK KMS, but not detected by Trivy
module "datasync_opg_ingress_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_18:Access logging not enabled currently
  #checkov:skip=CKV_AWS_21:Versioning is enabled, but not detected by Checkov
  #checkov:skip=CKV_AWS_145:Bucket is encrypted with CMK KMS, but not detected by Checkov
  #checkov:skip=CKV_AWS_300:Lifecycle configuration not enabled currently
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required currently
  #checkov:skip=CKV2_AWS_6:Public access block is enabled, but not detected by Checkov
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not enabled currently
  #checkov:skip=CKV2_AWS_62:Bucket notifications not required currently
  #checkov:skip=CKV2_AWS_67:Regular CMK key rotation is not required currently

  for_each = local.analytical_platform_ingestion_environments

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.8.0"

  bucket = "mojap-data-production-datasync-opg-ingress-${each.key}"

  force_destroy = true

  versioning = {
    enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_opg_ingress_bucket_policy[each.key].json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.datasync_opg_kms[each.key].key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
