# ------------------------------------------------------------------------
# Lake Formation - admin permissions
# https://user-guide.modernisation-platform.service.justice.gov.uk/runbooks/adding-admin-data-lake-formation-permissions.html
# ------------------------------------------------------------------------
data "aws_iam_role" "github_actions" {
  name = "GlobalGitHubActionAdmin"
}

data "aws_iam_roles" "probation_cadet" {
  name_regex = "probation-cadet-*"
}

resource "aws_lakeformation_data_lake_settings" "settings" {
  admins = flatten(
    [
      "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/aws-reserved/sso.amazonaws.com/eu-west-2/${data.aws_iam_role.aws_sso_modernisation_platform_data_eng.name}",
      data.aws_iam_role.github_actions.arn,
      data.aws_iam_roles.probation_cadet.arns
    ]
  )

  create_database_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

  create_table_default_permissions {
    # These settings should replicate current behaviour: LakeFormation is Ignored
    permissions = ["ALL"]
    principal   = "IAM_ALLOWED_PRINCIPALS"
  }

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
      effect  = "Allow"
      actions = ["s3:ListBucket"]
      resources = [
        module.datalake_dev.bucket.arn,
        module.datalake_preprod.bucket.arn,
        module.datalake_prod.bucket.arn,
        module.datalake_prod_dev.bucket.arn
      ]
    }
    S3ObjectAccess = {
      effect  = "Allow"
      actions = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
      resources = [
        "${module.datalake_dev.bucket.arn}/*",
        "${module.datalake_preprod.bucket.arn}/*",
        "${module.datalake_prod.bucket.arn}/*",
        "${module.datalake_prod_dev.bucket.arn}/*"
      ]
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
locals {
  probation_data_bucket_arns = {
    dev      = module.datalake_dev.bucket.arn
    preprod  = module.datalake_preprod.bucket.arn
    prod     = module.datalake_prod.bucket.arn
    prod_dev = module.datalake_prod_dev.bucket.arn
  }

  raw_databases = ["ppud_dev", "ppud_preprod", "ppud_prod"]

  curated_databases = ["ppud_dev_dbt", "ppud_preprod_dbt", "ppud"]

  derived_databases = ["stg_ppud_prod_dev_dbt"]

  derived_databases_prod = ["stg_ppud"]
}

resource "aws_lakeformation_resource" "probation_data_buckets" {
  for_each = local.probation_data_bucket_arns

  arn                   = each.value
  role_arn              = module.lakeformation_registration_iam_role.arn
  hybrid_access_enabled = true
}

resource "aws_lakeformation_permissions" "probation_datalake_data_location" {
  for_each = local.probation_data_bucket_arns

  permissions = [
    "DATA_LOCATION_ACCESS"
  ]
  principal = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  data_location {
    arn = each.value
  }
}

# ------------------------------------------------------------------------
# Lake Formation - grant permissions
# ------------------------------------------------------------------------
resource "aws_lakeformation_opt_in" "probation_datalake_view_databases" {
  for_each = toset(concat(local.curated_databases, local.raw_databases, local.derived_databases_prod))

  principal {
    data_lake_principal_identifier = data.aws_iam_role.aws_sso_mp_analytics_eng.arn
  }

  resource_data {
    database {
      name       = each.value
      catalog_id = "189157455002"
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_view_databases" {
  for_each = toset(concat(local.curated_databases, local.raw_databases, local.derived_databases_prod))

  permissions = ["DESCRIBE"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  database {
    name       = each.value
    catalog_id = "189157455002"
  }
}

resource "aws_lakeformation_opt_in" "probation_datalake_curated" {
  for_each = toset(concat(local.curated_databases, local.derived_databases_prod))

  principal {
    data_lake_principal_identifier = data.aws_iam_role.aws_sso_mp_analytics_eng.arn
  }
  resource_data {
    table {
      database_name = each.value
      wildcard      = true
      catalog_id    = "189157455002"
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_curated" {
  for_each = toset(concat(local.curated_databases, local.derived_databases_prod))

  permissions = ["SELECT", "DESCRIBE"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  table {
    database_name = each.value
    wildcard      = true
    catalog_id    = "189157455002"
  }
}

resource "aws_lakeformation_opt_in" "probation_datalake_databases_derived" {
  for_each = toset(local.derived_databases)

  principal {
    data_lake_principal_identifier = data.aws_iam_role.aws_sso_mp_analytics_eng.arn
  }

  resource_data {
    database {
      name       = each.value
      catalog_id = "189157455002"
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_databases_derived" {
  for_each = toset(local.derived_databases)

  permissions = ["CREATE_TABLE", "DESCRIBE"]
  principal   = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  database {
    name       = each.value
    catalog_id = "189157455002"
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
      catalog_id    = "189157455002"
    }
  }
}

resource "aws_lakeformation_permissions" "probation_datalake_derived" {
  for_each = toset(local.derived_databases)

  permissions = [
    "SELECT", "INSERT", "DELETE", "DESCRIBE", "ALTER", "DROP"
  ]
  principal = data.aws_iam_role.aws_sso_mp_analytics_eng.arn

  table {
    database_name = each.value
    wildcard      = true
    catalog_id    = "189157455002"
  }
}
