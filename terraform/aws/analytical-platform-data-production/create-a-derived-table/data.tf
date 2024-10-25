data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_kms_alias" "mojap_apc_prod_cadet_replication_bucket" {
  name = "s3/mojap-derived-tables-replication"
}

data "aws_kms_alias" "s3_source" {
  name = "alias/aws/s3"
}

data "aws_kms_alias" "s3_destination" {
  provider = aws.analytical-platform-data-production-eu-west-2
  name     = "alias/aws/s3"
}
