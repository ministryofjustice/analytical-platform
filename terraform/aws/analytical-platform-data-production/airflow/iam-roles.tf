module "airflow_analytical_platform_development_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.28.0"

  create_role = true

  role_name = "airflow-analytical-platform-development"

  role_policy_arns = {
    policy = module.airflow_analytical_platform_development_iam_policy.arn
  }

  oidc_providers = {
    one = {
      provider_arn               = resource.aws_iam_openid_connect_provider.analytical_platform_development.arn
      namespace_service_accounts = ["airflow:airflow"]
    }
  }
}

resource "aws_iam_role" "airflow_dev_execution_role" {
  name               = "airflow-dev-execution-role"
  description        = "Execution role for Airflow dev"
  assume_role_policy = data.aws_iam_policy_document.airflow_dev_execution_assume_role_policy.json

  inline_policy {
    name   = "airflow-dev-execution-role-policy"
    policy = data.aws_iam_policy_document.airflow_dev_execution_role_policy.json
  }
}