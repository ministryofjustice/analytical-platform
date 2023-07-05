resource "aws_kms_alias" "export_rds_snapshot_to_S3_alias" {
  name          = "alias/export_rds_snapshot_to_S3"
  target_key_id = aws_kms_key.export_rds_snapshot_to_S3.key_id
}