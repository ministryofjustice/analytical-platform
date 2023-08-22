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
