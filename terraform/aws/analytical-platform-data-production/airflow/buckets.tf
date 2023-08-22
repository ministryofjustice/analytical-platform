resource "aws_s3_bucket" "mojap_airflow_dev" {
  bucket = "mojap-airflow-dev"

}

resource "aws_s3_bucket_public_access_block" "mojap_airflow_dev_access_block" {
  bucket = aws_s3_bucket.mojap_airflow_dev.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "requirements" {
  bucket = "mojap-airflow-dev"
  key    = "requirements.txt"
  source = "./files/requirements.txt"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = filemd5("./files/requirements.txt")
}
