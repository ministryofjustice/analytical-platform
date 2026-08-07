resource "aws_s3_bucket" "antony-terraform-training-task1-bucket" {
  bucket = "antony-terraform-training-task1-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "antony-terraform-training-task1-bucket-public-access-block" {
  bucket                  = aws_s3_bucket.antony-terraform-training-task1-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "antony-terraform-training-task1-bucket-versioning" {
  bucket = aws_s3_bucket.antony-terraform-training-task1-bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "antony-terraform-training-task1-bucket-encryption" {
  bucket = aws_s3_bucket.antony-terraform-training-task1-bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "antony-terraform-training-task1-bucket-object" {
  bucket                 = aws_s3_bucket.antony-terraform-training-task1-bucket.id
  key                    = "antony-terraform-training-task1-bucket-object.txt"
  content                = "This is a test object for the Antony Terraform Training Task 1 S3 bucket."
  server_side_encryption = "AES256"
}
