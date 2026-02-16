resource "aws_secretsmanager_secret" "slack_webhook" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-dev-slack-webhook"
  kms_key_id = module.dms_dev_kms.key_arn
}

resource "aws_secretsmanager_secret" "oasys_dev_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-dev-secret"
  kms_key_id = module.dms_dev_kms.key_arn
}

resource "aws_secretsmanager_secret" "delius_dev_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "delius-dev-secret"
  kms_key_id = module.dms_dev_kms.key_arn
}
