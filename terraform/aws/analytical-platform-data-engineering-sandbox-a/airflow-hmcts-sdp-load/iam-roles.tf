module "airflow_hmcts_sdp_load_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.34.0"

  name = "github-airflow-hmcts-sdp-load"

  subjects = ["moj-analytical-services/airflow-hmcts-sdp-load:*"]

  policies = {
    airflow_hmcts_sdp_load = module.airflow_hmcts_sdp_load_iam_policy.arn
  }
}
