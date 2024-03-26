
module "development_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket        = "mojap-data-production-bold-egress-development"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.development_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

module "production_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.0"

  bucket        = "mojap-data-production-bold-egress-production"
  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.production_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
