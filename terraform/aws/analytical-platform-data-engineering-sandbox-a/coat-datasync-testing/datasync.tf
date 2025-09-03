### This represents the root account datasync setup

# SOURCE - Root account S3 location - i.e. sandbox for testing
resource "aws_datasync_location_s3" "root_account" {
  s3_bucket_arn = module.coat_s3.s3_bucket_arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = "arn:aws:iam::684969100054:role/coat-datasync-iam-role" #TODO: Update call
  }
}

# DESTINATION - APDP
resource "aws_datasync_location_s3" "apdp_account" {
  region        = "eu-west-1"
  s3_bucket_arn = "arn:aws:s3:::mojap-data-production-coat-cur-reports-v2-hourly" #TODO: Update how this is derived in the root account
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = "arn:aws:iam::684969100054:role/coat-datasync-iam-role" #TODO: Update call
  }
}

resource "aws_datasync_task" "coat_to_apdp_task" {
  destination_location_arn = aws_datasync_location_s3.apdp_account.arn
  name                     = "COAT to APDP"
  source_location_arn      = aws_datasync_location_s3.root_account.arn

  cloudwatch_log_group_arn = module.datasync_events_log_group.cloudwatch_log_group_arn

  options {
    log_level         = "BASIC"
    posix_permissions = "NONE"
    uid               = "NONE"
    gid               = "NONE"
  }
}
