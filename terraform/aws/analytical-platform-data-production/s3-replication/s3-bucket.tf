#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "alpha_mojap_ho_data_transfer_test" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = "alpha-mojap-ho-data-transfer-test"

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  replication_configuration = {
    role = aws_iam_role.alpha_mojap_ho_data_transfer_replication.arn
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
  to = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket_lifecycle_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}

import {
  to = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket_server_side_encryption_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}

import {
  to = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket_versioning.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}

import {
  to = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket_logging.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}

import {
  to = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket_public_access_block.this[0]
  id = "alpha-mojap-ho-data-transfer-test"
}

moved {
  from = module.alpha-mojap-ho-data-transfer-test.data.aws_caller_identity.current
  to   = module.alpha_mojap_ho_data_transfer_test.data.aws_caller_identity.current
}

moved {
  from = module.alpha-mojap-ho-data-transfer-test.data.aws_partition.current
  to   = module.alpha_mojap_ho_data_transfer_test.data.aws_partition.current
}

moved {
  from = module.alpha-mojap-ho-data-transfer-test.data.aws_region.current
  to   = module.alpha_mojap_ho_data_transfer_test.data.aws_region.current
}

moved {
  from = module.alpha-mojap-ho-data-transfer-test.aws_s3_bucket.this[0]
  to   = module.alpha_mojap_ho_data_transfer_test.aws_s3_bucket.this[0]
}
