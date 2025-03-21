# OIDC Provider for the EKS cluster in AP account
resource "aws_iam_openid_connect_provider" "ap_compute_production" {
  client_id_list = ["sts.amazonaws.com"]
  url            = var.eks_oidc_url
}

# Permissions for the GitHub Actions runner
data "aws_iam_policy_document" "create_a_derived_table" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:DeleteObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::dbt-tables-sandbox/*",
      "arn:aws:s3:::dbt-tables-sandbox",
      "arn:aws:s3:::dbt-query-dump-sandbox/*",
      "arn:aws:s3:::dbt-query-dump-sandbox",
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
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:datacatalog/*",
      "arn:aws:athena:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:workgroup/*"
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
      "glue:CreateDatabase"
    ]
    resources = [
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:schema/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:database/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:table/*/*",
      "arn:aws:glue:*:${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:catalog"
    ]
  }
}

module "create_a_derived_table_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.52.2"

  name_prefix = "create-a-derived-table"
  policy      = data.aws_iam_policy_document.create_a_derived_table.json
}

# Role for the GitHub Actions runner to assume using the OIDC provider
module "create_a_derived_table_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  role_name            = "create-a-derived-table"
  max_session_duration = 10800

  role_policy_arns = {
    policy = module.create_a_derived_table_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn = aws_iam_openid_connect_provider.ap_compute_production.arn
      namespace_service_accounts = [
        "actions-runners:actions-runner-mojas-create-a-derived-table",
        "actions-runners:actions-runner-mojas-create-a-derived-table-non-spot"
      ]
    }
  }
}
