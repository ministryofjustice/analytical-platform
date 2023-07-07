##################################################
# AWS
##################################################

# Calling session
data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

data "aws_kms_key" "rds_s3_export" {
  key_id = "alias/rds-s3-export"
}
