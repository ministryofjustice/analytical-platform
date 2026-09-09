module "github_actions_secret_check_iam_policy" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  #checkov:skip=CKV_TF_2:Module registry does not support tags for versions

  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "6.6.1"

  name_prefix = "github-actions-secret-check"
  description = "IAM policy for GitHub Actions to check AWS Secrets Manager expiry tags"

  policy = data.aws_iam_policy_document.github_actions_secret_check.json

}

data "aws_iam_policy_document" "github_actions_secret_check" {

  statement {
    sid    = "AllowSecretsManagerList"
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::312423030077:role/github-actions-secret-check"
    ]
  }
}
