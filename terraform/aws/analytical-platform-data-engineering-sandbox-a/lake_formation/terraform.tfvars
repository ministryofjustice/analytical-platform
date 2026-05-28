##################################################
# General
##################################################
account_ids = {
  analytical-platform-data-engineering-sandbox-a = "684969100054"
  analytical-platform-management-production      = "042130406152"
}

tags = {
  business-unit        = "HMPPS"
  application          = "Data Engineering"
  component            = "Data Engineering lake_formation"
  environment          = "sandbox"
  is-production        = "false"
  owner                = "Data Engineering:dataengineering@digital.justice.gov.uk"
  source-code          = "https://github.com/ministryofjustice/analytical-platform/tree/rds-export-test/terraform/aws/analytical-platform-data-engineering-sandbox-a/lake_formation"
  de-sandbox-nuke-keep = "true"
}


restricted_principal_arn = "arn:aws:iam::684969100054:role/aws-reserved/sso.amazonaws.com/eu-west-2/AWSReservedSSO_modernisation-platform-data-eng_19ac4a28d1fccd44"

restricted_tables = {
  offenders_main = {
    database_name = "antony_lf_mock_data_dev_dbt"
    table_name    = "table_name_offenders_main"

    allowed_columns = [
      "last",
      "first",
      "gender"

    ]

    row_filter = "gender = 'FEMALE'"
  }
}