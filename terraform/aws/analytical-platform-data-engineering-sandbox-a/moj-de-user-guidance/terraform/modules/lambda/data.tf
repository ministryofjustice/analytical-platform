# terraform/modules/lambda/data.tf
# References pre-staged Lambda artifacts in the bootstrap-owned artifacts bucket.
# Zips are built + uploaded by build_and_upload.sh in the SOURCE repo.
# etag is used as source_code_hash so a re-uploaded zip triggers a Lambda update.

data "aws_s3_object" "layer" {
  bucket = var.artifacts_bucket
  key    = var.layer_s3_key
}

data "aws_s3_object" "function" {
  bucket = var.artifacts_bucket
  key    = var.function_s3_key
}

data "aws_s3_object" "authorizer" {
  bucket = var.artifacts_bucket
  key    = var.authorizer_s3_key
}
