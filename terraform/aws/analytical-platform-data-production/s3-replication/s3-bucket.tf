#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "replication_buckets" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  for_each = local.replication_configurations

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.12.0"

  bucket = each.value.source_bucket_name

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

  replication_configuration = lookup(local.replication_configs, each.key, {})

  logging = {
    target_bucket = "moj-analytics-s3-logs"
    target_prefix = "${each.value.source_bucket_name}/"
    target_object_key_format = {
      simple_prefix = {}
    }
  }

  lifecycle_rule = [
    {
      enabled = true
      id      = "${each.value.source_bucket_name}_lifecycle_configuration"

      transition = {
        days          = 0
        storage_class = "INTELLIGENT_TIERING"
      }
    }
  ]
}

moved {
  from = module.alpha_mojap_ho_data_transfer_test
  to   = module.replication_buckets["test"]
}

moved {
  from = module.alpha_mojap_ho_data_transfer.aws_s3_bucket.this[0]
  to   = module.replication_buckets["production"].aws_s3_bucket.this[0]
}

import {
  to = module.replication_buckets["production"].aws_s3_bucket_lifecycle_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.replication_buckets["production"].aws_s3_bucket_server_side_encryption_configuration.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.replication_buckets["production"].aws_s3_bucket_versioning.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.replication_buckets["production"].aws_s3_bucket_logging.this[0]
  id = "alpha-mojap-ho-data-transfer"
}

import {
  to = module.replication_buckets["production"].aws_s3_bucket_public_access_block.this[0]
  id = "alpha-mojap-ho-data-transfer"
}
