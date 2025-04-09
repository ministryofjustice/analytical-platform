module "dms_test_metadata" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket_prefix = "dms-test-metadata-"
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
module "dms_test_rawhist" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket_prefix = "dms-test-raw-history-"
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
module "dms_test_landing" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket_prefix = "dms-test-landing-"
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
module "dms_test_lambda" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket_prefix = "dms-test-lambda-functions-"
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