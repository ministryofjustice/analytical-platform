data "aws_iam_policy_document" "mlflow_access" {
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::alpha-analytical-platform-mlflow-development",
      "arn:aws:s3:::alpha-analytical-platform-mlflow-development/*"
    ]
  }
}

module "mlflow_access_iam_policy" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.44.0"

  name_prefix = "github-mlflow-access"

  policy = data.aws_iam_policy_document.mlflow_access.json
}

module "mlflow_access_iam_role" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.44.0"

  name = "github-mlflow-access"

  subjects = ["moj-analytical-services/mlflow-access:*"]

  policies = {
    github_mlflow_access = module.mlflow_access_iam_policy.arn
  }
}
