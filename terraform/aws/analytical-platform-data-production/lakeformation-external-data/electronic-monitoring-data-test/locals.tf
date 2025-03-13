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
      name        = "staged_fms_test_dbt"
      permissions = ["DESCRIBE"]

    }
  ]
  tables = [
    {
      source_table         = "account"
      source_database      = "staged_fms_test_dbt"
      data_filter_name     = "filter-account-acfd15b3547e6c190937dabba14245cdf39af4256bc72fffdb64f9c91e0e1144"
      permissions          = ["SELECT", "DESCRIBE"]
      destination_database = { database_name = "staged_fms_test_dbt" }
    }
  ]

  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
