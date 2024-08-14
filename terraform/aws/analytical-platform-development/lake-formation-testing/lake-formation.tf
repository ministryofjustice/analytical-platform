data "aws_caller_identity" "session" {
  provider = aws.session
}

data "aws_iam_session_context" "session" {
  provider = aws.session

  arn = data.aws_caller_identity.session.arn
}

module "lake_formation" {
  source = "git::https://github.com/ministryofjustice/terraform-aws-analytical-platform-lakeformation.git?ref=database-target-rename"
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

  tables_to_share = [
    {
      resource_link_table_name = "gary-apd-ireland-table"
      source_table             = "gary-apd-ireland-table"
      source_database          = "gary-apd-ireland-database"
      destination_database = {
        database_name   = "gary-apd-ireland-database-destination",
        create_database = true
      }
    }
  ]

  providers = {
    aws.source      = aws                                                # eu-west-1 source account - ap management prod
    aws.destination = aws.analytical-platform-data-development-eu-west-1 # eu-west-2 destination account
  }
}
