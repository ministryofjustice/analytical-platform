resource "aws_kms_key" "export_rds_snapshot_to_S3" {
  description              = "Export RDS snapshot to S3"
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  policy                   = data.aws_iam_policy_document.kms_key_policy.json
}