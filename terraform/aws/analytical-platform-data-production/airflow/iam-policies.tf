data "aws_iam_policy_document" "airflow_analytical_platform_development" {
  statement {
    sid       = "AllowS3"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}

module "airflow_analytical_platform_development_iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.28.0"

  name = "airflow-analytical-platform-development"

  policy = data.aws_iam_policy_document.airflow_analytical_platform_development.json
}
