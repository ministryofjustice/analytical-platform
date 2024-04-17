module "cjs_dashboard_airflow_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.39.0"

  name = "github-cjs-dashboard-airflow"

  subjects = ["ministryofjustice/airflow-cjs-dashboard-data:*"]

  policies = {
    cjs_dashboard_airflow = module.cjs_dashboard_airflow_iam_policy.arn
  }
}
