module "airflow_bucket" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.2"

  bucket = "mojap-development-airflow"

  force_destroy = true

  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = true
      apply_server_side_encryption_by_default = {
        kms_master_key_id = module.airflow_s3_kms.key_arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
