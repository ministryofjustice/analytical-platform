#This file is temporary file to be deleted after successful Terraform apply

# The following list of blocks for all the test buckets.
import {
  to = module.s3_bucket_source_zip_test.aws_s3_bucket.this[0]
  id = local.splink_source_zip_bucket_test_name
}

import {
  to = module.s3_bucket_audit_test.aws_s3_bucket.this[0]
  id = local.splink_audit_bucket_test_name
}

import {
  to = module.s3_bucket_search_input_test.aws_s3_bucket.this[0]
  id = local.splink_search_input_bucket_test_name
}

import {
  to = module.s3_bucket_search_output_test.aws_s3_bucket.this[0]
  id = local.splink_search_output_bucket_test_name
}

import {
  to = module.s3_bucket_source_input_test.aws_s3_bucket.this[0]
  id = local.splink_source_input_bucket_test_name
}

import {
  to = module.s3_bucket_source_output_test.aws_s3_bucket.this[0]
  id = local.splink_source_output_bucket_test_name
}

import {
  to = module.s3_bucket_source_test.aws_s3_bucket.this[0]
  id = local.splink_source_bucket_test_name
}
