data "aws_iam_policy_document" "airflow_hmcts_sdp_load" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox",
      "arn:aws:s3:::alpha-hmcts-de-testing-sandbox/*"
    ]
  }
}

module "airflow_hmcts_sdp_load_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.34.0"

  name_prefix = "github-airflow-hmcts-sdp-load"

  policy = data.aws_iam_policy_document.airflow_hmcts_sdp_load.json
}
