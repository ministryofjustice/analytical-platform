data "aws_iam_policy_document" "mojap_cadet_production_replication" {
  statement {
    sid    = "DestinationBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::${local.mojap_apc_prod_cadet_replication_bucket}/*"]
  }
  statement {
    sid    = "SourceBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket"
    ]
    resources = [module.mojap_cadet_production.s3_bucket_arn]
  }
  statement {
    sid    = "SourceBucketObjectPermissions"
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.mojap_cadet_production.s3_bucket_arn}/*"]
  }
  # statement {
  #   sid    = "SourceBucketKMSKey"
  #   effect = "Allow"
  #   actions = [
  #     "kms:Decrypt",
  #     "kms:GenerateDataKey"
  #   ]
  #   resources = [module.production_kms.key_arn]
  # }
  statement {
    sid    = "DestinationBucketKMSKey"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:eu-west-2:${var.account_ids["analytical-platform-compute-production"]}:key/${local.mojap_apc_prod_cadet_replication_kms_key_id}"]
  }
}

module "mojap_cadet_production_replication_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.47.1"

  name_prefix = "mojap-data-production-cadet-to-apc-production"

  policy = data.aws_iam_policy_document.mojap_cadet_production_replication.json
}
