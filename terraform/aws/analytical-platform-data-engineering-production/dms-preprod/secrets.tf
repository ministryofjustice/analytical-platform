resource "aws_secretsmanager_secret" "slack_webhook" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-preprod-slack-webhook"
  kms_key_id = module.dms_preprod_kms.key_arn
}

resource "aws_secretsmanager_secret" "oasys_preprod_secret" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "oasys-preprod-secret"
  kms_key_id = module.dms_preprod_kms.key_arn
}
