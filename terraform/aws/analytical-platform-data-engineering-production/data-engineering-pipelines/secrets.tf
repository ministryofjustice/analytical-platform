module "ae_download_athena_csv_secret" {
  #checkov:skip=CKV_TF_1: Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2: Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.1.0"

  name_prefix = "ae_download_athena_csv_slack_webhook_"

  create_random_password = true
  random_password_length = 10

  tags = var.tags
}
