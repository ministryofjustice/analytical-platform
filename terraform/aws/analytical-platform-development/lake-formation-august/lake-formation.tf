data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

module "lake_formation" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation.git?ref=0.2.0"
  data_locations = [
    {
      data_location = "arn:aws:s3:::dev-gary-aug-test"
      hybrid_mode   = true
      register      = true
      share         = true
    }
  ]
  databases_to_share = [
    {
      name             = "dev_gary_aug_test_database"
      permissions      = ["DESCRIBE"]
      share_all_tables = true
    }
  ]

  #   tables_to_share = [
  #     {
  #       resource_link_table_name = "gary-apd-ireland-table"
  #       source_table             = "gary-apd-ireland-table"
  #       source_database          = "gary-apd-ireland-database"
  #       destination_database = {
  #         database_name   = "gary-apd-ireland-database-destination",
  #         create_database = true
  #       }
  #     }

  providers = {
    aws.source      = aws                                                   # eu-west-1 source account - analytical-platform-development
    aws.destination = aws.analytical-platform-compute-development-eu-west-2 # eu-west-2 destination account - analytical-platform-compute-development
  }
}
