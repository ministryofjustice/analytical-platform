locals {
  source_databases = [
    {
      source_name = "derived_test_dbt"
    }
  ]
  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
