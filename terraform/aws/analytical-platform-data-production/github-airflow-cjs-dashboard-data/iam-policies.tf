data "aws_iam_policy_document" "github_airflow_cjs_dashboard_data" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-cjs-scorecard",
      "arn:aws:s3:::alpha-cjs-scorecard/*"
    ]
  }
}

module "github_airflow_cjs_dashboard_data_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.39.0"

  name_prefix = "github-airflow-cjs-dashboard-data"

  policy = data.aws_iam_policy_document.github_airflow_cjs_dashboard_data.json
}
