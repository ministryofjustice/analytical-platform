locals {
  data_locations = [
    {
      data_location = "arn:aws:s3:::dpr-structured-historical-development"
      hybrid_access = true
      register      = true
      share         = true

    }
  ]

  databases = [
    {
      name                         = "dpr-ap-integration-test"
      share_all_tables             = true
      share_all_tables_permissions = ["DESCRIBE", "SELECT"]

    }
  ]

  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
