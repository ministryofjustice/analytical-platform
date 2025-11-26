#tfsec:ignore:AVD-AWS-0089:Bucket logging not enabled currently
module "mojap_national_security_data_s3" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.8.2"

  bucket = "mojap-data-production-national-security-data"

  force_destroy = true

  versioning = {
    enabled = true
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.mojap_national_security_data_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
