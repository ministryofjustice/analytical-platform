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
  source = "./files/prod/requirements.txt"

  etag                   = filemd5("./files/prod/requirements.txt")
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
  statement {
    sid = "DenyInsecureTransport"
    actions = [
      "s3:*"
    ]

    effect = "Deny"

    principals {
      type = "*"
      identifiers = [
        "*"
      ]
    }
    resources = [
      "arn:aws:s3:::mojap-airflow-prod/*",
      "arn:aws:s3:::mojap-airflow-prod"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false"
      ]
    }
  }
}
