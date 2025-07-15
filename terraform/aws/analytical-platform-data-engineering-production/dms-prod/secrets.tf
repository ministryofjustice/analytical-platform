resource "aws_secretsmanager_secret" "slack_webhook" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-prod-slack-webhook"
  kms_key_id = module.dms_prod_kms.key_arn
}

resource "aws_secretsmanager_secret" "oasys_prod_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-prod-secret"
  kms_key_id = module.dms_prod_kms.key_arn
}

resource "aws_secretsmanager_secret" "prod_slack_webhook" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "prod-slack-webhook"
  kms_key_id = module.dms_prod_kms.key_arn
}

resource "aws_secretsmanager_secret" "delius_prod_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "delius-prod-secret"
  kms_key_id = module.dms_prod_kms.key_arn
}
