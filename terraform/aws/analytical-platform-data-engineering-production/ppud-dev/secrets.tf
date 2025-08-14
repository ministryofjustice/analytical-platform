resource "aws_secretsmanager_secret" "rds_export" {
  # checkov:skip=CKV2_AWS_57: Skipping because automatic rotation not needed.
  name       = "rds_ppud_export_dev"
  kms_key_id = module.rds_export_kms_dev.key_arn
  tags       = var.tags
}
