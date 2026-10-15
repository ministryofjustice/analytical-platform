module "slack_webhook_secret" {
  # checkov:skip=CKV_TF_1: Module registry does not support commit hashes for versions
  # checkov:skip=CKV_TF_2: Module registry does not support tags for versions

  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "2.2.0"

  name_prefix = "slack_webhook_${local.name}_${local.env}"

  create_random_password = true
  random_password_length = 10

  tags = var.tags
}
