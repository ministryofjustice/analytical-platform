module "cjs_dashboard_app_iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.33.0"

  name = "github-cjs-dashboard-app"

  subjects = ["ministryofjustice/cjs_scorecard_exploratory_analysis:*"]

  policies = {
    cjs_dashboard_app = module.cjs_dashboard_app_iam_policy.arn
  }
}
