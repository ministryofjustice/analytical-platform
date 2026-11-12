#The following imports Test S3 Buckets to resolve Terraform apply error.

import {
  to = module.s3_bucket_audit_test.aws_s3_bucket.this[0]
  id = "laa-search-audit-test"
}

import {
  to = module.s3_bucket_search_input_test.aws_s3_bucket.this[0]
  id = "laa-splink-search-input-test"
}

import {
  to = module.s3_bucket_search_output_test.aws_s3_bucket.this[0]
  id = "laa-splink-search-output-test"
}

import {
  to = module.s3_bucket_source_input_test.aws_s3_bucket.this[0]
  id = "laa-splink-source-file-input-test"
}

import {
  to = module.s3_bucket_source_output_test.aws_s3_bucket.this[0]
  id = "laa-splink-source-file-output-test"
}

import {
  to = module.s3_bucket_source_test.aws_s3_bucket.this[0]
  id = "laa-splink-source-s3-test"
}

import {
  to = module.s3_bucket_source_zip_test.aws_s3_bucket.this[0]
  id = "laa-splink-source-zip-test"
}

import {
  to = module.s3_bucket_splink_test.aws_s3_bucket.this[0]
  id = "laa-splink-search-s3-test"
}
