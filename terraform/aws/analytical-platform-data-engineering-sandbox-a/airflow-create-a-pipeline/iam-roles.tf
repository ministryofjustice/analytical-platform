module "airflow_create_a_pipeline_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "6.0.0"

  name = "github-airflow-create-a-pipeline"

  subjects = ["moj-analytical-services/airflow-create-a-pipeline:*"]

  policies = {
    airflow_create_a_pipeline = module.airflow_create_a_pipeline_iam_policy.arn
  }
}
