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
  version = "5.4.0"

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

data "aws_iam_policy_document" "datasync_laa_ingress_bucket_policy" {
  statement {
    sid    = "DataSyncLAAReplicationPermissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-ingestion-production"]}:role/laa-data-analysis-production-replication"]
    }
    actions = [
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:GetObjectVersionTagging",
      "s3:ReplicateTags",
      "s3:ReplicateDelete"
    ]
    resources = ["arn:aws:s3:::mojap-data-production-datasync-laa-ingress-production/*"]
  }
}

# Policy for LAA logging bucket
data "aws_iam_policy_document" "datasync_laa_logs_bucket_policy" {
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["arn:aws:s3:::mojap-s3-bucket-access-logs-eu-west-2/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_ids["analytical-platform-data-production"]]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:s3:::mojap-data-production-datasync-laa-ingress-production"]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl"
    ]
    resources = ["arn:aws:s3:::mojap-s3-bucket-access-logs-eu-west-2"]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_ids["analytical-platform-data-production"]]
    }
  }
}

#tfsec:ignore:AVD-AWS-0088:Bucket is encrypted with CMK KMS, but not detected by Trivy
#tfsec:ignore:AVD-AWS-0132:Bucket is encrypted with CMK KMS, but not detected by Trivy
module "datasync_laa_ingress_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions
  #checkov:skip=CKV_AWS_21:Versioning is enabled, but not detected by Checkov
  #checkov:skip=CKV_AWS_145:Bucket is encrypted with CMK KMS, but not detected by Checkov
  #checkov:skip=CKV_AWS_300:Lifecycle configuration not enabled currently
  #checkov:skip=CKV_AWS_144:Cross-region replication is not required currently
  #checkov:skip=CKV2_AWS_6:Public access block is enabled, but not detected by Checkov
  #checkov:skip=CKV2_AWS_61:Lifecycle configuration not enabled currently
  #checkov:skip=CKV2_AWS_62:Bucket notifications not required currently
  #checkov:skip=CKV2_AWS_67:Regular CMK key rotation is not required currently

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.4.0"

  bucket = "mojap-data-production-datasync-laa-ingress-production"

  force_destroy = true

  versioning = {
    enabled = true
  }

  logging = {
    target_bucket = module.mojap_access_logging_eu_west_2_s3.s3_bucket_id
    target_prefix = "access-logs/"
    target_object_key_format = {
      partitioned_prefix = {
        partition_date_source = "EventTime"
      }
    }
  }
  attach_inventory_destination_policy = true
  inventory_self_source_destination   = true

  inventory_configuration = {
    inventory-csv = {
      included_object_versions = "All"

      destination = {
        format = "CSV"
        prefix = "inventory/csv/"
      }


      frequency = "Daily"

      optional_fields = [
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus",
        "ObjectLockRetainUntilDate",
        "ObjectLockMode",
        "ObjectLockLegalHoldStatus",
        "IntelligentTieringAccessTier",
        "BucketKeyStatus",
        "ChecksumAlgorithm",
        "ObjectAccessControlList",
        "ObjectOwner"
      ]
    },

    inventory-parquet = {
      included_object_versions = "All"

      destination = {
        format = "Parquet"
        prefix = "inventory/parquet/"
      }

      frequency = "Daily"

      optional_fields = [
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus",
        "ObjectLockRetainUntilDate",
        "ObjectLockMode",
        "ObjectLockLegalHoldStatus",
        "IntelligentTieringAccessTier",
        "BucketKeyStatus",
        "ChecksumAlgorithm",
        "ObjectAccessControlList",
        "ObjectOwner"
      ]
    }
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_laa_ingress_bucket_policy.json

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.datasync_laa_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

#tfsec:ignore:AVD-AWS-0088:Bucket is encrypted with CMK KMS, but not detected by Trivy
#tfsec:ignore:AVD-AWS-0132:Bucket is encrypted with CMK KMS, but not detected by Trivy
module "mojap_access_logging_eu_west_2_s3" {
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

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.4.0"

  bucket = "mojap-s3-bucket-access-logs-eu-west-2"

  force_destroy = true

  versioning = {
    enabled                   = true
    bucket_versioning_enabled = true
  }

  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_laa_logs_bucket_policy.json

  # Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}
