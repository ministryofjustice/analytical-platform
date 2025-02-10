module "datasync_opg_development" {
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
  version = "4.5.0"

  bucket        = "mojap-data-production-datasync-opg-development"
  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_opg_development.json

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.datasync_opg_development_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "datasync_opg_development" {

  statement {
    sid    = "Permissions on objects"
    effect = "Allow"
    actions = [
      "s3:ReplicateDelete",
      "s3:ReplicateObject",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${module.datasync_opg_development.s3_bucket_arn}/*"]
    principals {
      type = "AWS"
      identifiers = [
        local.environment_configurations.development.datasync_opg_replication_iam_role_arn
      ]
    }
  }

  statement {
    sid    = "Permissions on bucket"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [module.datasync_opg_development.s3_bucket_arn]
    principals {
      type = "AWS"
      identifiers = [
        local.environment_configurations.development.datasync_opg_replication_iam_role_arn
      ]
    }
  }
}

module "datasync_opg_production" {
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
  version = "4.5.0"

  bucket        = "mojap-data-production-datasync-opg"
  force_destroy = true

  attach_policy = true
  policy        = data.aws_iam_policy_document.datasync_opg_production.json

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.datasync_opg_production_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

data "aws_iam_policy_document" "datasync_opg_production" {

  statement {
    sid    = "Permissions on objects"
    effect = "Allow"
    actions = [
      "s3:ReplicateDelete",
      "s3:ReplicateObject"
    ]
    resources = ["${module.datasync_opg_production.s3_bucket_arn}/*"]
    principals {
      type = "AWS"
      identifiers = [
        local.environment_configurations.production.datasync_opg_replication_iam_role_arn
      ]
    }
  }

  statement {
    sid    = "Permissions on bucket"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetBucketVersioning",
      "s3:PutBucketVersioning"
    ]
    resources = [module.datasync_opg_production.s3_bucket_arn]
    principals {
      type = "AWS"
      identifiers = [
        local.environment_configurations.production.datasync_opg_replication_iam_role_arn
      ]
    }
  }
}
