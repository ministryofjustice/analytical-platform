module "query_results_dev" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-query-results-dev-"

  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = []

  sse_algorithm = "AES256"

  tags = merge(var.tags, 
    {
      "environment" = "dev"
      "is_production" = "false"
    }
  )  
}

module "datalake_dev" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-datalake-dev-"

  versioning_enabled = true
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = []

  sse_algorithm = "AES256"

  tags = merge(var.tags, 
    {
      "environment" = "dev"
      "is_production" = "false"
    }
  )  
}
