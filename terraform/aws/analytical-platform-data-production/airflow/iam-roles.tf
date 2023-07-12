module "airflow_analytical_platform_development_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.27.0"

  create_role = true

  role_name = "airflow-analytical-platform-development"

  role_policy_arns = {
    policy = module.airflow_analytical_platform_development_iam_policy.arn
  }

  oidc_providers = {
    one = {
      provider_arn = format(
        "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:oidc-provider/%s",
        replace(data.aws_eks_cluster.analytical_platform_development.identity[0].oidc[0].issuer, "https://", "")
      )
      namespace_service_accounts = ["airflow:airflow"]
    }
  }
}
