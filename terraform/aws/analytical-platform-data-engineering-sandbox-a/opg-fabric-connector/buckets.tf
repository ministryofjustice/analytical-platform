#trivy:ignore:AVD-AWS-0089
module "opg_fabric_store" {
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source        = "terraform-aws-modules/s3-bucket/aws"
  version       = "5.8.2"
  bucket        = "alpha-opg-fabric-sandbox"
  force_destroy = false
  versioning = {
    enabled = true
  }
  server_side_encryption_configuration = {
    rule = {
      bucket_key_enabled = false
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true


  attach_policy = true
  policy = jsonencode(
    {
      Statement = [
        {
          Sid    = "Set-permissions-for-objects"
          Effect = "Allow"
          Principal = {
            AWS = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/iam_role_s3_bucket_moj_database_source_dev"
            ]
          }
          Action = [
            "s3:ReplicateObject",
            "s3:ReplicateDelete"
          ]
          Resource = "arn:aws:s3:::mojap-data-engineering-production-ppud-dev/*"
        },
        {
          Sid    = "Set-permissions-on-bucket"
          Effect = "Allow"
          Principal = {
            AWS = [
              "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/iam_role_s3_bucket_moj_database_source_dev"
            ]
          }
          Action = [
            "s3:GetBucketVersioning",
            "s3:PutBucketVersioning"
          ]
          Resource = "arn:aws:s3:::mojap-data-engineering-production-ppud-dev"
        }
      ]
      Version = "2012-10-17"
    }
  )
}
