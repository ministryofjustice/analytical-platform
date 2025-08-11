module "secrets_manager_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  aliases               = ["secretsmanager/airflow"]
  description           = "Airflow Service Secrets Manager KMS Key"
  enable_default_policy = true
  multi_region          = true

  deletion_window_in_days = 7
}

module "secrets_manager_eu_west_1_replica_kms" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/kms/aws"
  version = "4.0.0"

  providers = {
    aws = aws.eu-west-1
  }

  aliases               = ["secretsmanager/airflow"]
  description           = "Airflow Service Secrets Manager KMS Key"
  enable_default_policy = true
  create_replica        = true
  primary_key_arn       = module.secrets_manager_kms.key_arn

  deletion_window_in_days = 7
}
