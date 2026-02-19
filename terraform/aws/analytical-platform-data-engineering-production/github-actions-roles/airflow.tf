module "cadet_airflow_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  version = "6.4.0"

  name = "probation-cadet-airflow-dev"

  policies = {
    policy = module.create_a_derived_table_dev_iam_policy.arn
  }

  oidc_providers = {
    analytical-platform-compute-development = {
      provider_arn = format(
        "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:oidc-provider/%s",
        trimprefix(jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-development-oidc-endpoint"], "https://")
      )
      namespace_service_accounts = ["mwaa:probation-cadet"]
    }
  }

  tags = merge(var.tags,
    {
      "environment"   = "dev"
      "is_production" = "false"
    }
  )

}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute_dev_cluster_oidc_provider" {
  url = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-development-oidc-endpoint"]

  client_id_list = [
    "sts.amazonaws.com",
  ]

}