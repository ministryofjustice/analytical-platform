# terraform/modules/lambda/artifacts_bucket.tf
# Bucket #3 — stores Lambda deployment artifacts (layer + function + authorizer zips)
# Created by Terraform → destroyed/recreated as part of the nuke cycle.

resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project_name}-${var.environment}-lambda-artifacts"
  force_destroy = true  # allow `terraform destroy` to wipe versioned objects during nuke

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-lambda-artifacts"
    Description = "Lambda deployment artifacts - layer + function code"
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-old-artifact-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}