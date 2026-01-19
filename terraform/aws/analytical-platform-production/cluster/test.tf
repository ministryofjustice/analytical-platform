resource "aws_s3_bucket" "prod_example" {
  bucket = "my-bucket-name"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "prod_example" {
  bucket = aws_s3_bucket.prod_example.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "prod_example" {
  bucket = aws_s3_bucket.prod_example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
