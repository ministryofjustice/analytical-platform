module "cjs_dashboard_app_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.33.1"

  name = "github-cjs-dashboard-app"

  subjects = ["ministryofjustice/cjs_scorecard_exploratory_analysis:*"]

  policies = {
    cjs_dashboard_app = module.cjs_dashboard_app_iam_policy.arn
  }
}
