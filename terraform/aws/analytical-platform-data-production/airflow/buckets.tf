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
  etag                   = filemd5("./files/requirements.txt")
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "kubeconfig_dev" {
  bucket = "mojap-airflow-dev"
  key    = "dags/.kube/config"
  source = "./files/dev/config"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag                   = filemd5("./files/dev/config")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_policy" "airflow_dev_bucket_policy" {
  bucket = aws_s3_bucket.mojap_airflow_dev.id
  policy = data.aws_iam_policy_document.airflow_bucket_policy.json
}

data "aws_iam_policy_document" "airflow_bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/data-ga-s3-sync"]
    }

    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions"
    ]

    resources = [
      aws_s3_bucket.mojap_airflow_dev.arn,
      "${aws_s3_bucket.mojap_airflow_dev.arn}/*",
    ]
  }
}

############################ AIRFLOW PRODUCTION INFRASTRUCTURE

resource "aws_s3_bucket" "mojap_airflow_prod" {
  bucket = "mojap-airflow-prod"
}

resource "aws_s3_bucket_public_access_block" "mojap_airflow_prod_access_block" {
  bucket = aws_s3_bucket.mojap_airflow_prod.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "kubeconfig_prod" {
  bucket = "mojap-airflow-prod"
  key    = "dags/.kube/config"
  source = "./files/prod/config"

  etag                   = filemd5("./files/prod/config")
  server_side_encryption = "AES256"
}

resource "aws_s3_object" "requirements_prod" {
  bucket = "mojap-airflow-prod"
  key    = "requirements.txt"
  source = "./files/requirements.txt"

  etag                   = filemd5("./files/requirements.txt")
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_policy" "allow_s3_sync_role_to_see_prod_bucket" {
  bucket = aws_s3_bucket.mojap_airflow_prod.id
  policy = data.aws_iam_policy_document.allow_s3_sync_role_to_see_prod_bucket.json
}

data "aws_iam_policy_document" "allow_s3_sync_role_to_see_prod_bucket" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/data-ga-s3-sync"]
    }

    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions"
    ]

    resources = [
      aws_s3_bucket.mojap_airflow_prod.arn,
      "${aws_s3_bucket.mojap_airflow_prod.arn}/*"
    ]
  }
}
