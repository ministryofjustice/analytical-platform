data "aws_caller_identity" "current" {}

locals {
  expected_account_id = "593291632749"
  expected_region     = "eu-west-1"

  catalog_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id

  database_name = "mock_ppud_dev_dbt"
  table_name    = "table_1"

  athena_principal_arn = "arn:aws:iam::593291632749:role/AWSReservedSSO_modernisation-platform-data-eng_499410b42334a7d7"

  visible_columns = [
    "last",
    "first",
    "block",
    "gender",
    "region",
  ]
}

resource "terraform_data" "assert_expected_context" {
  lifecycle {
    precondition {
      condition     = local.catalog_id == local.expected_account_id
      error_message = "Lake Formation apply is running in AWS account ${local.catalog_id}, but ${local.database_name}.${local.table_name} exists in account ${local.expected_account_id}."
    }

    precondition {
      condition     = local.region == local.expected_region
      error_message = "Lake Formation apply is running in region ${local.region}, but ${local.database_name}.${local.table_name} exists in region ${local.expected_region}."
    }
  }
}

# This data source is supported and will fail early if the table is absent.
data "aws_glue_catalog_table" "table_1" {
  database_name = local.database_name
  name          = local.table_name

  depends_on = [terraform_data.assert_expected_context]
}

# Register the S3 location that backs the table.
resource "aws_lakeformation_resource" "table_1_data_location" {
  arn = "arn:aws:s3:::mojap-derived-tables/mock_ppud_dev_dbt/table_1"

  depends_on = [data.aws_glue_catalog_table.table_1]
}

resource "aws_lakeformation_permissions" "table_1_database_describe" {
  principal   = local.athena_principal_arn
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.catalog_id
    name       = local.database_name
  }

  depends_on = [
    aws_lakeformation_resource.table_1_data_location,
    data.aws_glue_catalog_table.table_1,
  ]
}

resource "aws_lakeformation_permissions" "table_1_first_five_columns" {
  principal   = local.athena_principal_arn
  permissions = ["SELECT"]

  table_with_columns {
    catalog_id    = local.catalog_id
    database_name = local.database_name
    name          = local.table_name
    column_names  = local.visible_columns
  }

  depends_on = [
    aws_lakeformation_resource.table_1_data_location,
    data.aws_glue_catalog_table.table_1,
  ]
}

output "lakeformation_apply_context" {
  value = {
    account_id = local.catalog_id
    region     = local.region
    database   = local.database_name
    table      = data.aws_glue_catalog_table.table_1.name
  }
}
