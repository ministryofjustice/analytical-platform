#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "mojap_national_security_data_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = "mojap-data-production-national-security-data"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_national_security_data_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "alpha-mojap-ho-data-transfer-test" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = "alpha-mojap-ho-data-transfer-test"

  versioning = {
    enabled = true
  }

  replication_configuration = var.alpha_mojap_ho_data_transfer_replication_enabled ? {
    role = aws_iam_role.alpha_mojap_ho_data_transfer_replication[0].arn
    rules = [
      {
        id                        = "alpha-mojap-ho-data-transfer-test-replication"
        status                    = "Enabled"
        delete_marker_replication = true

        destination = {
          account_id    = "591168578261"
          bucket        = "arn:aws:s3:::dsa-cdl-police-s3-deposit-cjs-npa"
          storage_class = "STANDARD"

          access_control_translation = {
            owner = "Destination"
          }
        }
      }
    ]
  } : {}

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  logging = {
    target_bucket = "moj-analytics-s3-logs"
    target_prefix = "alpha-mojap-ho-data-transfer-test/"
    target_object_key_format = {
      simple_prefix = {}
    }
  }

  lifecycle_rule = [
    {
      enabled = true
      id      = "alpha-mojap-ho-data-transfer-test_lifecycle_configuration"

      transition = {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

import {
  to = module.alpha-mojap-ho-data-transfer-test.aws_s3_bucket.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}
