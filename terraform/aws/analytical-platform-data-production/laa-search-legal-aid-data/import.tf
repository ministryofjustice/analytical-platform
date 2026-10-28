
#This file is temporary file to be deleted after successful Terraform apply

import {
  to = module.s3_bucket_splink.aws_s3_bucket_versioning.this[0]
  id = local.splink_bucket_name
}
