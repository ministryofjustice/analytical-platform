provider "aws" {
  alias  = "lakeformation_eu_west_1"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  alias  = "consumer_593291632749"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::593291632749:role/GlobalGitHubActionAdmin"
  }
}

data "aws_caller_identity" "lakeformation_current" {
  provider = aws.lakeformation_eu_west_1
}

data "aws_region" "lakeformation_current" {
  provider = aws.lakeformation_eu_west_1
}

data "aws_iam_roles" "modernisation_platform_mwaa_user" {
  provider = aws.consumer_593291632749

  name_regex  = "AWSReservedSSO_modernisation-platform-mwaa-user_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

data "aws_iam_role" "modernisation_platform_mwaa_user_role" {
  provider = aws.consumer_593291632749

  name = one(data.aws_iam_roles.modernisation_platform_mwaa_user.names)
}

locals {
  expected_account_id = var.account_ids["analytical-platform-data-engineering-production"]
  expected_region     = "eu-west-1"

  catalog_id = data.aws_caller_identity.lakeformation_current.account_id
  region     = data.aws_region.lakeformation_current.id

  database_name = "mock_ppud_dev_dbt"
  table_name    = "offenders_main"

  restricted_columns = [
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

resource "aws_lakeformation_permissions" "mwaa_user_database_describe" {
  provider = aws.lakeformation_eu_west_1

  principal   = data.aws_iam_role.modernisation_platform_mwaa_user_role.arn
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

resource "aws_lakeformation_permissions" "mwaa_user_first_five_columns" {
  provider = aws.lakeformation_eu_west_1

  principal   = data.aws_iam_role.modernisation_platform_mwaa_user_role.arn
  permissions = ["SELECT"]

  table_with_columns {
    catalog_id    = local.catalog_id
    database_name = local.database_name
    name          = local.table_name
    column_names  = local.restricted_columns
  }

  depends_on = [
    aws_lakeformation_resource.offenders_main_data_location,
    data.aws_glue_catalog_table.offenders_main,
  ]
}

output "lakeformation_apply_context" {
  value = {
    producer_account = local.catalog_id
    producer_region  = local.region
    database         = local.database_name
    table            = data.aws_glue_catalog_table.offenders_main.name
    external_role    = data.aws_iam_role.modernisation_platform_mwaa_user_role.arn
  }
}
