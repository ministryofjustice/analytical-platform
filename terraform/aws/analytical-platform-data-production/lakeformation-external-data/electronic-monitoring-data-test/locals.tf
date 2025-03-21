locals {
  data_locations = [
    {
      data_location = "arn:aws:s3:::emds-cadt-test"
      hybrid_access = false
      register      = true
      share         = true

    }
  ]

  databases = [
    {
      name        = "mart_test_dbt"
      permissions = ["DESCRIBE"]

    }
  ]
  tables = [
    {
      source_table         = "visits"
      source_database      = "mart_test_dbt"
      data_filter_name     = ""
      permissions          = ["SELECT"]
      destination_database = { database_name = "mart_test_dbt" }
    }
  ]

  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
