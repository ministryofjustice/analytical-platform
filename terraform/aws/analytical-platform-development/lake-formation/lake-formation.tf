data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

module "lake_formation" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation.git?ref=feature/configure-lake-formation-sharing"
  data_locations = [
    {
      data_location = "arn:aws:s3:::lf-antfmoj-test"
      hybrid_mode   = true
      register      = true
      share         = true
    }
  ]
  databases_to_share = [
    {
      name        = "antfmoj_test_db"
      target_db   = "antfmoj_test_db_target"
      permissions = ["DESCRIBE"]
    }
  ]
  providers = {
    aws.source = aws #eu-west-1
    # aws.target_account = aws.analytical-platform-management-production
    aws.target = aws.analytical-platform-management-production-eu-west-2
  }
}
