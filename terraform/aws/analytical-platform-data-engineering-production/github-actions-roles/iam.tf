data "aws_iam_policy_document" "create_a_derived_table_dev" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:DeleteObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::de-probation-datalake-dev/*",
      "arn:aws:s3:::de-probation-datalake-dev",
      "arn:aws:s3:::de-probation-query-results-dev/*",
      "arn:aws:s3:::de-probation-query-results-dev",
      "arn:aws:s3:::de-probation-datalake-preprod/*",
      "arn:aws:s3:::de-probation-datalake-preprod",
      "arn:aws:s3:::de-probation-query-results-preprod/*",
      "arn:aws:s3:::de-probation-query-results-preprod",
    ]
  }
  statement {
    sid    = "DataAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
  }
  statement {
    sid    = "AthenaAccess"
    effect = "Allow"
    actions = [
      "athena:List*",
      "athena:Get*",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]
    resources = [
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-engineering-production"]}:datacatalog/*",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-engineering-production"]}:workgroup/*"
    ]
  }
  statement {
    sid    = "GlueAccess"
    effect = "Allow"
    actions = [
      "glue:Get*",
      "glue:DeleteTable",
      "glue:DeleteTableVersion",
      "glue:DeleteSchema",
      "glue:DeletePartition",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:UpdateSchema",
      "glue:UpdatePartition",
      "glue:UpdateDatabase",
      "glue:CreateTable",
      "glue:CreateSchema",
      "glue:CreatePartition",
      "glue:CreatePartitionIndex",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-production"]}:schema/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-production"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-production"]}:table/*/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-production"]}:catalog"
    ]
  }
}

module "create_a_derived_table_dev_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "probation-cadet-dev"
  policy      = data.aws_iam_policy_document.create_a_derived_table_dev.json
}

module "create_a_derived_table_dev_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.2.3"

  name                 = "probation-cadet-dev"
  max_session_duration = 10800

  policies = {
    policy = module.create_a_derived_table_dev_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn = format(
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:oidc-provider/%s",
        trimprefix(jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-production-oidc-endpoint"], "https://")
      )
      namespace_service_accounts = ["actions-runner-mojas-cadt-probation-dev"]
    }
  }
}

# unsure if the below is required as not being used anywhere
resource "aws_iam_openid_connect_provider" "analytical_platform_compute_cluster_oidc_provider" {
  url = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-production-oidc-endpoint"]

  client_id_list = [
    "sts.amazonaws.com",
  ]

}
