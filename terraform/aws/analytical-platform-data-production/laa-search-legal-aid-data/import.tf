
#This file is temporary file to be deleted after successful Terraform apply

import {
  to = module.s3_bucket_audit.aws_s3_bucket.this[0]
  id = local.splink_audit_bucket_name
}

import {
  to = module.s3_bucket_search_input.aws_s3_bucket.this[0]
  id = local.splink_search_input_bucket_name
}

import {
  to = module.s3_bucket_search_output.aws_s3_bucket.this[0]
  id = local.splink_search_output_bucket_name
}

import {
  to = module.s3_bucket_source.aws_s3_bucket.this[0]
  id = local.splink_source_bucket_name
}

import {
  to = module.s3_bucket_source_input.aws_s3_bucket.this[0]
  id = local.splink_source_input_bucket_name
}

import {
  to = module.s3_bucket_source_output.aws_s3_bucket.this[0]
  id = local.splink_source_output_bucket_name
}

import {
  to = module.s3_bucket_source_zip.aws_s3_bucket.this[0]
  id = local.splink_source_zip_bucket_name
}
