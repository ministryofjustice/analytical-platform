provider "aws" {
  alias  = "lakeformation_eu_west_1"
  region = "eu-west-1"
}

data "aws_caller_identity" "current" {
  provider = aws.lakeformation_eu_west_1
}

locals {
  expected_account_id = "189157455002"
  expected_region     = "eu-west-1"

  catalog_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.id

  database_name = "mock_ppud_dev_dbt"
  table_name    = "offenders_main"

  athena_principal_arn = "arn:aws:iam::189157455002:role/AWSReservedSSO_modernisation-platform-data-eng_89c7a4cbe024b69a"

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

data "aws_glue_catalog_table" "offenders_main" {
  provider = aws.lakeformation_eu_west_1

  database_name = local.database_name
  name          = local.table_name

  depends_on = [terraform_data.assert_expected_context]
}

resource "aws_lakeformation_resource" "offenders_main_data_location" {
  provider = aws.lakeformation_eu_west_1

  arn = "arn:aws:s3:::probation-datalake-dev-20251218164046759500000001/data/dev/models/domain_name=antony_test/database_name=mock_ppud_dev_dbt/table_name=offenders_main"

  depends_on = [data.aws_glue_catalog_table.offenders_main]
}

resource "aws_lakeformation_permissions" "offenders_main_database_describe" {
  provider = aws.lakeformation_eu_west_1

  principal   = local.athena_principal_arn
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.catalog_id
    name       = local.database_name
  }

  depends_on = [
    aws_lakeformation_resource.offenders_main_data_location,
    data.aws_glue_catalog_table.offenders_main,
  ]
}

resource "aws_lakeformation_permissions" "offenders_main_first_five_columns" {
  provider = aws.lakeformation_eu_west_1

  principal   = local.athena_principal_arn
  permissions = ["SELECT"]

  table_with_columns {
    catalog_id    = local.catalog_id
    database_name = local.database_name
    name          = local.table_name
    column_names  = local.visible_columns
  }

  depends_on = [
    aws_lakeformation_resource.offenders_main_data_location,
    data.aws_glue_catalog_table.offenders_main,
  ]
}

output "lakeformation_apply_context" {
  value = {
    account_id = local.catalog_id
    region     = local.region
    database   = local.database_name
    table      = data.aws_glue_catalog_table.offenders_main.name
    principal  = local.athena_principal_arn
  }
}
