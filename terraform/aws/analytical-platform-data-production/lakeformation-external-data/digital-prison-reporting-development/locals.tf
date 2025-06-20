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
      name                         = "dpr_ap_integration_test_tag_dev_dbt"
      share_all_tables             = true
      share_all_tables_permissions = ["DESCRIBE", "SELECT"]

    }
  ]

  tables_to_share = [
    {
      source_database = "dpr_ap_integration_test_tag_dev_dbt"
      source_table    = "dev_model_1_notag"
      destination_database = {
        database_name   = "dpr_ap_integration_test_tag_dev_dbt_resource_link"
        create_database = false
      }
      permissions = ["DESCRIBE", "SELECT"]
    },
    {
      source_database = "dpr_ap_integration_test_tag_dev_dbt"
      source_table    = "dev_model_2_tag"
      destination_database = {
        database_name   = "dpr_ap_integration_test_tag_dev_dbt_resource_link"
        create_database = false
      }
      permissions = ["DESCRIBE", "SELECT"]
    }
  ]

  account_ids = jsondecode(data.aws_secretsmanager_secret_version.account_ids_version.secret_string)
}
