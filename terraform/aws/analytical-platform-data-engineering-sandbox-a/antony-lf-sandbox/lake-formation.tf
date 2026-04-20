terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

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

provider "aws" {
  alias  = "sandbox_a_eu_west_1"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::684969100054:role/GlobalGitHubActionAdmin"
  }
}

provider "aws" {
  alias  = "data_engineering_production_eu_west_1"
  region = "eu-west-1"

  assume_role {
    role_arn = "arn:aws:iam::189157455002:role/GlobalGitHubActionAdmin"
  }
}

data "aws_caller_identity" "sandbox_a" {
  provider = aws.sandbox_a_eu_west_1
}

data "aws_region" "sandbox_a" {
  provider = aws.sandbox_a_eu_west_1
}

data "aws_caller_identity" "data_engineering_production" {
  provider = aws.data_engineering_production_eu_west_1
}

locals {
  producer_catalog_id = data.aws_caller_identity.sandbox_a.account_id
  producer_region     = data.aws_region.sandbox_a.id
  consumer_catalog_id = data.aws_caller_identity.data_engineering_production.account_id

  database_name = "antony_lf_mock_data_dev_dbt"
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
      condition     = local.producer_catalog_id == "684969100054"
      error_message = "Producer-side Lake Formation is running in AWS account ${local.producer_catalog_id}, but expected sandbox-a account 684969100054."
    }

    precondition {
      condition     = local.producer_region == "eu-west-1"
      error_message = "Producer-side Lake Formation is running in region ${local.producer_region}, but expected eu-west-1."
    }

    precondition {
      condition     = local.consumer_catalog_id == "189157455002"
      error_message = "Consumer-side account is ${local.consumer_catalog_id}, but expected analytical-platform-data-engineering-production account 189157455002."
    }
  }
}

data "aws_glue_catalog_table" "offenders_main" {
  provider = aws.sandbox_a_eu_west_1

  database_name = local.database_name
  name          = local.table_name

  depends_on = [terraform_data.assert_expected_context]
}

resource "aws_lakeformation_resource" "offenders_main_data_location" {
  provider = aws.sandbox_a_eu_west_1

  arn = "arn:aws:s3:::alpha-antony-lf-bucket/data/dev/models/domain_name=antony_test/database_name=antony_lf_mock_data_dev_dbt/table_name=offenders_main"

  depends_on = [data.aws_glue_catalog_table.offenders_main]
}

resource "aws_lakeformation_permissions" "share_database_to_data_engineering_production" {
  provider = aws.sandbox_a_eu_west_1

  principal   = local.consumer_catalog_id
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.producer_catalog_id
    name       = local.database_name
  }

  depends_on = [
    aws_lakeformation_resource.offenders_main_data_location,
    data.aws_glue_catalog_table.offenders_main,
  ]
}

resource "aws_lakeformation_permissions" "share_restricted_table_to_data_engineering_production" {
  provider = aws.sandbox_a_eu_west_1

  principal   = local.consumer_catalog_id
  permissions = ["SELECT"]

  table_with_columns {
    catalog_id    = local.producer_catalog_id
    database_name = local.database_name
    name          = local.table_name
    column_names  = local.restricted_columns
  }

  depends_on = [
    aws_lakeformation_resource.offenders_main_data_location,
    data.aws_glue_catalog_table.offenders_main,
  ]
}

resource "aws_glue_catalog_database" "antony_lf_mock_data_dev_dbt_link" {
  provider = aws.data_engineering_production_eu_west_1

  name = "antony_lf_mock_data_dev_dbt_link"

  target_database {
    catalog_id    = local.producer_catalog_id
    database_name = local.database_name
    region        = "eu-west-1"
  }

  depends_on = [
    aws_lakeformation_permissions.share_database_to_data_engineering_production,
    aws_lakeformation_permissions.share_restricted_table_to_data_engineering_production,
  ]
}

output "lakeformation_apply_context" {
  value = {
    producer_account = local.producer_catalog_id
    producer_region  = local.producer_region
    consumer_account = local.consumer_catalog_id
    source_database  = local.database_name
    source_table     = data.aws_glue_catalog_table.offenders_main.name
    linked_database  = aws_glue_catalog_database.antony_lf_mock_data_dev_dbt_link.name
    producer_s3_path = "s3://alpha-antony-lf-bucket/data/dev/models/domain_name=antony_test/database_name=antony_lf_mock_data_dev_dbt/table_name=offenders_main/"
  }
}
