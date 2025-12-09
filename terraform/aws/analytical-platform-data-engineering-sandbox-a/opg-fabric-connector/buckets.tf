#trivy:ignore:AVD-AWS-0089
module "opg_fabric_store" {
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "5.8.2"
  bucket        = "alpha-opg-fabric-sandbox"
  force_destroy = false
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
