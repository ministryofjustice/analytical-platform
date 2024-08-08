data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

module "lake_formation" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation.git?ref=0.1.0"
  data_locations = [
    {
      data_location = "arn:aws:s3:::gary-apd-s3"
      hybrid_mode   = true
      register      = true
      share         = true
    }
  ]
  databases_to_share = [
    {
      name             = "gary-apd-ireland-database"
      permissions      = ["DESCRIBE"]
      share_all_tables = false
    }
  ]

  providers = {
    aws.source = aws                                                # eu-west-1 source account
    aws.target = aws.analytical-platform-data-development-eu-west-2 # eu-west-2 target account
  }
}
