import {
  to = module.s3_bucket_splink.aws_s3_bucket.this[0]
  id = "laa-splink-search-s3"
}

import {
  to = module.s3_bucket_audit.aws_s3_bucket.this[0]
  id = "laa-search-audit"
}

import {
  to = module.s3_bucket_search_input.aws_s3_bucket.this[0]
  id = "laa-splink-search-input"
}

import {
  to = module.s3_bucket_search_output.aws_s3_bucket.this[0]
  id = "laa-splink-search-output"
}

import {
  to = module.s3_bucket_source.aws_s3_bucket.this[0]
  id = "laa-splink-source-s3"
}

import {
  to = module.s3_bucket_source_input.aws_s3_bucket.this[0]
  id = "laa-splink-source-file-input"
}

import {
  to = module.s3_bucket_source_output.aws_s3_bucket.this[0]
  id = "laa-splink-source-file-output"
}

import {
  to = module.s3_bucket_source_zip.aws_s3_bucket.this[0]
  id = "laa-splink-source-zip"
}
