data "aws_iam_policy_document" "cjs_dashboard_app" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:List*",
      "s3:GetObject*",
      "s3:GetBucket*",
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
  version = "5.33.0"

  name_prefix = "cjs-dashboard-app"

  policy = data.aws_iam_policy_document.cjs_dashboard_app.json
}
