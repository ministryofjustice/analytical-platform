### This represents the root account datasync setup

# SOURCE - Root account S3 location - i.e. sandbox for testing
resource "aws_datasync_location_s3" "root_account" {
  s3_bucket_arn = module.coat_s3.s3_bucket_arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = "arn:aws:iam::684969100054:role/coat-datasync-iam-role" #TODO: Update this
  }
}

# DESTINATION - APDP
resource "aws_datasync_location_s3" "apdp_account" {
  s3_bucket_arn = "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly" #TODO: Update how this is derived in the root account
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = "arn:aws:iam::684969100054:role/coat-datasync-iam-role" #TODO: I don't have a role defined here so this is wrong
  }
}
