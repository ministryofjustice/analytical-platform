data "aws_iam_policy_document" "create_a_derived_table" {
  # checkov:skip=CKV_AWS_111:Permissions for CaDeT to create derived tables
  # checkov:skip=CKV_AWS_356:CaDeT requires access to all resources to create derived tables
  statement {
    effect = "Allow"
    actions = [
      "glue:GetTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:CreateTable",
      "glue:DeleteTable",
      "glue:CreateDatabase",
      "glue:DeleteDatabase",
      "glue:UpdateTable",
      "glue:CreatePartition",
      "glue:BatchCreatePartition",
      "glue:UpdatePartition",
      "glue:GetPartition",
      "glue:GetPartitions",
    ]
    resources = ["*"]
  }
}

module "create_a_derived_table_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.2.3"

  name_prefix = "create-a-derived-table"
  policy      = data.aws_iam_policy_document.create_a_derived_table.json
}

module "create_a_derived_table_iam_role" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.6.0"

  role_name            = "create-a-derived-table"
  max_session_duration = 10800

  role_policy_arns = {
    policy = module.create_a_derived_table_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-production = {
      provider_arn = format(
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:oidc-provider/%s",
        trimprefix(jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-production-oidc-endpoint"], "https://")
      )
      namespace_service_accounts = [
        "actions-runners:actions-runner-mojas-cadt-sandbox-a",
        "actions-runners:actions-runner-mojas-cadt-sandbox-a-non-spot"
      ]
    }
  }
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute_cluster_oidc_provider" {
  url = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-production-oidc-endpoint"]

  client_id_list = [
    "sts.amazonaws.com",
  ]

}
