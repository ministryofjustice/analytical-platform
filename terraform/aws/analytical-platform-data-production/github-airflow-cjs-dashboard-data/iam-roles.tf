module "github_airflow_cjs_dashboard_data_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.43.0"

  name = "github-airflow-cjs-dashboard-data"

  subjects = ["moj-analytical-services/airflow-cjs-dashboard-data:*"]

  policies = {
    github_airflow_cjs_dashboard_data = module.github_airflow_cjs_dashboard_data_iam_policy.arn
  }
}
