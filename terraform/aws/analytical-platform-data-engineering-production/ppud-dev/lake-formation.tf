data "aws_caller_identity" "current" {}

locals {
  catalog_id = data.aws_caller_identity.current.account_id

  athena_principal_arn = "arn:aws:iam::593291632749:role/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"

  visible_columns = [
    "last",
    "first",
    "block",
    "gender",
    "region",
  ]
}

# Register the S3 location that backs the table.
# Registering the S3 path is required for LF-governed Athena access.
resource "aws_lakeformation_resource" "table_1_data_location" {
  arn = "arn:aws:s3:::mojap-derived-tables/mock_ppud_dev_dbt/table_1"
}

# Let the role browse the database in Athena.
resource "aws_lakeformation_permissions" "table_1_database_describe" {
  principal   = local.athena_principal_arn
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.catalog_id
    name       = "mock_ppud_dev_dbt"
  }
}

# Let the role see only the first five columns.
resource "aws_lakeformation_permissions" "table_1_first_five_columns" {
  principal   = local.athena_principal_arn
  permissions = ["SELECT"]

  table_with_columns {
    catalog_id    = local.catalog_id
    database_name = "mock_ppud_dev_dbt"
    name          = "table_1"
    column_names  = local.visible_columns
  }
}