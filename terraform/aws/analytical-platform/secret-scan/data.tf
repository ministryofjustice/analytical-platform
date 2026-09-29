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

data "aws_iam_policy_document" "github_actions_secret_check_management_production" {
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
      "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/github-actions-secret-check",
      "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:role/github-actions-secret-check",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-development"]}:role/github-actions-secret-check",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/github-actions-secret-check",
      "arn:aws:iam::${var.account_ids["analytical-platform-landing-production"]}:role/github-actions-secret-check"
    ]
  }
}
