data "aws_iam_policy_document" "terraform" {
  statement {
    sid    = "AllowKMS"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    resources = [module.terraform_kms.key_arn]
  }
  statement {
    sid       = "AllowS3List"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [module.terraform_bucket.s3_bucket_arn]
  }
  statement {
    sid    = "AllowS3Write"
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${module.terraform_bucket.s3_bucket_arn}/*"]
  }
}

module "terraform_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "5.58.0"

  name_prefix = "terraform"

  policy = data.aws_iam_policy_document.terraform.json
}

resource "aws_iam_role_policy_attachment" "terraform_github_analytical_platform_data_engineering" {
  role       = "github-analytical-platform-data-engineering"
  policy_arn = module.terraform_iam_policy.arn
}
