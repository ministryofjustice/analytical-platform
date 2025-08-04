resource "aws_secretsmanager_secret" "rds_export_sandbox" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "rds_export_sandbox"
  kms_key_id = module.rds_export_kms.key_arn
  tags = local.tags
}