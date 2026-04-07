# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# ------------------------------------------------------------------------

data "aws_iam_role" "github_actions" {
  name = "GlobalGitHubActionAdmin"
}

resource "aws_lakeformation_data_lake_settings" "settings" {
  admins = flatten(
    [
      "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/${data.aws_iam_role.aws_sso_modernisation_platform_data_eng.name}",
      data.aws_iam_role.github_actions.arn,
    ]
  )

  parameters = {
    "CROSS_ACCOUNT_VERSION" = "4"
  }
}

module "lakeformation_registration_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.2.1"

  name            = "lakeformation-registration"
  use_name_prefix = "false"

  trust_policy_permissions = {
    TrustRoleAndServiceToAssume = {
      actions = [
        "sts:AssumeRole",
        "sts:SetContext"
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["lakeformation.amazonaws.com"]
        },
        {
          type        = "Service"
          identifiers = ["glue.amazonaws.com"]
        },
      ]
    }
  }

  create_inline_policy = true
  inline_policy_permissions = {
    S3BucketAccess = {
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = [module.datalake_dev.bucket.arn]
    }
    S3ObjectAccess = {
      effect    = "Allow"
      actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = ["${module.datalake_dev.bucket.arn}/*"]
    }
    KMSKeyAccess = {
      effect = "Allow"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["arn:aws:kms:eu-west-2:${var.account_ids["analytical-platform-data-engineering-production"]}:key/alias/aws/s3"]
    }
  }
}

# ------------------------------------------------------------------------
# Lake Formation - register S3 resource
# ------------------------------------------------------------------------

resource "aws_lakeformation_resource" "probation_dev" {
  arn                   = module.datalake_dev.bucket.arn
  role_arn              = module.lakeformation_registration_iam_role.arn
  hybrid_access_enabled = true
}

# ------------------------------------------------------------------------
# Lake Formation - grant permissions
# ------------------------------------------------------------------------
locals {
  curated_databases = ["ppud_dev_dbt", "ppud_prod_dbt", "ppud_preprod_dbt"]

  derived_databases = ["public_protection_int_prod_dev_dbt", "stg_ppud_prod_dev_dbt"]
}

resource "aws_lakeformation_opt_in" "probation_datalake_curated" {
  for_each = toset(local.curated_databases)

  principal {
    data_lake_principal_identifier = data.aws_iam_role.aws_sso_mp_analytics_eng.arn
  }
  resource_data {
    table {
      database_name = each.value
      wildcard      = true
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_curated" {
  for_each = toset(local.curated_databases)

  permissions = ["SELECT", "DESCRIBE"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  table {
    database_name = each.value
    wildcard      = true
  }
}

resource "aws_lakeformation_opt_in" "probation_datalake_derived" {
  for_each = toset(local.derived_databases)

  principal {
    data_lake_principal_identifier = data.aws_iam_role.aws_sso_mp_analytics_eng.arn
  }
  resource_data {
    table {
      database_name = each.value
      wildcard      = true
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_databases_derived" {
  for_each = toset(local.derived_databases)

  permissions = ["CREATE_TABLE"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  database {
    name = each.value
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_derived" {
  for_each = toset(local.derived_databases)

  permissions = ["ALL"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  table {
    database_name = each.value
    wildcard      = true
  }
}
