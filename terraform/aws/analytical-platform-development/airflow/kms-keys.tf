module "airflow_s3_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "3.1.0"

  aliases               = ["s3/airflow"]
  description           = "Airflow S3 KMS key"
  enable_default_policy = true

  deletion_window_in_days = 7
}
