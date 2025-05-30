module "dms_test_mappings" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket_prefix = "dms-test-mappings-"
  force_destroy = true

  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "mappings" {
  bucket       = module.dms_test_mappings.s3_bucket_id
  key          = "test-mappings.json"
  source       = "${path.module}/test-mappings.json"
  content_type = "application/json"

  # To track changes to the file
  etag = filemd5("${path.module}/test-mappings.json")
}
