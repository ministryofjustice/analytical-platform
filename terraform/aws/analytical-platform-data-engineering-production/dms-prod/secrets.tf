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
