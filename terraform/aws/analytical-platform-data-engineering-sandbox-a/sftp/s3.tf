module "landing_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket = "analytical-platform-landing"
  # TODO: Is this needed below?
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_landing_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # TODO: Tagging
}

module "quarantine_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket = "analytical-platform-quarantine"
  # TODO: Is this needed below?
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.s3_quarantine_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # TODO: Tagging
}
