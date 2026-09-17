##################################################
# Secret scan
##################################################

data "aws_iam_policy_document" "github_actions_secret_check" {
  statement {
    sid    = "AllowSecretsManagerList"
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]
  }
}
