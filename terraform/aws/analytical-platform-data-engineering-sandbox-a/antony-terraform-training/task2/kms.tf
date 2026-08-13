resource "aws_kms_key" "bucket_key" {}

resource "aws_kms_alias" "bucket_key_alias" {
  name          = "alias/bucket-key"
  target_key_id = aws_kms_key.bucket_key.key_id
}
