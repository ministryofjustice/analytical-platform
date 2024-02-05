data "aws_iam_policy_document" "cjs_dashboard_app" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject"
    ]
    resources = [
      "arn:aws:s3:::mojap-cjs-dashboard",
      "arn:aws:s3:::mojap-cjs-dashboard/*"
    ]
  }
}

module "cjs_dashboard_app_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.34.0"

  name_prefix = "github-cjs-dashboard-app"

  policy = data.aws_iam_policy_document.cjs_dashboard_app.json
}
