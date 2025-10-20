#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "terraform_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.1"

  bucket = "mojap-data-engineering-production-terraform"

  force_destroy = true

  versioning = {
    status = "Enabled"
  }

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.terraform_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
