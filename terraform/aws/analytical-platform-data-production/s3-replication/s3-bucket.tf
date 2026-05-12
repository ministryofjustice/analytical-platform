#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "alpha_mojap_ho_data_transfer_test" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = local.replication_configurations["test"].source_bucket_name

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

  replication_configuration = lookup(local.replication_configs, "test", {})

  logging = {
    target_bucket = "moj-analytics-s3-logs"
    target_prefix = "${local.replication_configurations["test"].source_bucket_name}/"
    target_object_key_format = {
      simple_prefix = {}
    }
  }

  lifecycle_rule = [
    {
      enabled = true
      id      = "${local.replication_configurations["test"].source_bucket_name}_lifecycle_configuration"

      transition = {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

################### PRODUCTION REPLICATION #####################

#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "alpha_mojap_ho_data_transfer" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = local.replication_configurations["production"].source_bucket_name

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

  replication_configuration = lookup(local.replication_configs, "production", {})

  logging = {
    target_bucket = "moj-analytics-s3-logs"
    target_prefix = "${local.replication_configurations["production"].source_bucket_name}/"
    target_object_key_format = {
      simple_prefix = {}
    }
  }

  lifecycle_rule = [
    {
      enabled = true
      id      = "${local.replication_configurations["production"].source_bucket_name}_lifecycle_configuration"

      transition = {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

import {
  to = module.alpha_mojap_ho_data_transfer.aws_s3_bucket_lifecycle_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.alpha_mojap_ho_data_transfer.aws_s3_bucket_server_side_encryption_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.alpha_mojap_ho_data_transfer.aws_s3_bucket_versioning.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.alpha_mojap_ho_data_transfer.aws_s3_bucket_logging.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.alpha_mojap_ho_data_transfer.aws_s3_bucket_public_access_block.this[0]
  id = "alpha-mojap-ho-data-transfer"
}
