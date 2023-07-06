resource "aws_kms_alias" "rds_s3_export" {
  name          = "alias/rds-s3-export"
  target_key_id = aws_kms_key.rds_s3_export.key_id
}
