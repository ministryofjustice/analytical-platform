module "state_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.2.1"

  bucket = "global-tf-state-aqsvzyd5u9"
}

import {
  to = module.state_bucket.aws_s3_bucket.this[0]
  id = "global-tf-state-aqsvzyd5u9"
}

import {
  to = module.state_bucket.aws_s3_bucket_public_access_block.this[0]
  id = "global-tf-state-aqsvzyd5u9"
}
