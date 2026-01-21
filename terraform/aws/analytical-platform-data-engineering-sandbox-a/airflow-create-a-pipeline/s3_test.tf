resource "aws_s3_bucket" "example_2" {
  bucket = "my-bucket-name"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_versioning" "example_2" {
  bucket = aws_s3_bucket.example_2.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example_2" {
  bucket = aws_s3_bucket.example_2.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
