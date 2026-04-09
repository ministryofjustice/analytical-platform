module "query_results_dev" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-query-results-dev-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Enabled"
      "expiration" = {
        "days" = 1
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "dev"
      "is_production" = "false"
    }
  )
}

module "datalake_dev" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-datalake-dev-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Disabled"
      "expiration" = {
        "days" = 30
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "dev"
      "is_production" = "false"
    }
  )
}

module "query_results_preprod" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-query-results-preprod-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Enabled"
      "expiration" = {
        "days" = 1
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "preprod"
      "is_production" = "false"
    }
  )
}

module "datalake_preprod" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-datalake-preprod-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Disabled"
      "expiration" = {
        "days" = 30
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "preprod"
      "is_production" = "false"
    }
  )
}

module "datalake_prod_dev" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-datalake-prod-dev-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "prod_dev"
      "enabled" = "Enabled"
      "prefix"  = "prod_dev/"
      "expiration" = {
        "days" = 10
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "prod_dev"
      "is_production" = "false"
    }
  )
}

module "query_results_prod" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-query-results-prod-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Enabled"
      "expiration" = {
        "days" = 1
      }
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "prod"
      "is_production" = "true"
    }
  )
}

module "datalake_prod" {
  source        = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=9facf9fc8f8b8e3f93ffbda822028534b9a75399"
  bucket_prefix = "probation-datalake-prod-"

  versioning_enabled = false
  ownership_controls = "BucketOwnerEnforced"

  replication_enabled = false
  providers = {
    aws.bucket-replication = aws
  }

  lifecycle_rule = [
    {
      "id"      = "main"
      "enabled" = "Disabled"
    }
  ]

  sse_algorithm = "AES256"

  tags = merge(var.tags,
    {
      "environment"   = "prod"
      "is_production" = "true"
    }
  )
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_athena_results_eu_west_2" {
  bucket = "aws-athena-query-results-189157455002-eu-west-2"

  rule {
    id     = "expiry"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "aws_athena_results_eu_west_1" {
  bucket = "aws-athena-query-results-189157455002-eu-west-1"
  region = "eu_west_1"

  rule {
    id     = "expiry"
    status = "Enabled"
    expiration {
      days = 1
    }
  }
}
