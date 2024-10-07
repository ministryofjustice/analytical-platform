resource "aws_s3_bucket" "terraform_backend_sandbox" {
  bucket = "probation-de-sandbox-terraform-backend"

}

resource "aws_s3_bucket_public_access_block" "terraform_backend_access_block_sandbox" {
  bucket = aws_s3_bucket.terraform_backend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}