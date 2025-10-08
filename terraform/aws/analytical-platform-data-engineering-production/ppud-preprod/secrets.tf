module "rds_export_secret" {
  #checkov:skip=CKV_TF_1: Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2: Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "1.3.1"

  name_prefix = "rds_export_${local.name}_${local.env}"
  kms_key_id  = module.rds_export_kms.key_arn

  ignore_secret_changes  = true
  create_random_password = true
  random_password_length = 13

  tags = var.tags
}
