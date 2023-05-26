module "github-oidc-provider" {

  source                 = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v2.1.0"
  github_repositories    = ["ministryofjustice/data-platform:*", "ministryofjustice/analytical-platform-iam:*"]
  additional_permissions = data.aws_iam_policy_document.github_actions_iam_permissions.json
  role_name              = "github-actions-iam"
  tags_common            = local.tags
  tags_prefix            = "data-platform"
  providers = {
    aws = aws.management
  }

}

data "aws_iam_policy_document" "github_actions_iam_permissions" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    resources = formatlist("arn:aws:iam::%s:role/github-actions-infrastructure", values(local.accounts))
    actions   = ["sts:AssumeRole"]
  }
  statement {
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]
  }

  statement {
    sid       = "AllowOIDCReadState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/*", "arn:aws:s3:::global-tf-state-aqsvzyd5u9/"]
    actions = ["s3:Get*",
    "s3:List*"]
  }

  statement {
    sid       = "AllowOIDCWriteState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
    actions = ["s3:PutObject",
    "s3:PutObjectAcl"]
  }
  statement {
    sid       = "AllowDynamoDBStateLocking"
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
  }
}

module "github-oidc-provider-data-ecr" {

  source                 = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v2.1.0"
  github_repositories    = formatlist("ministryofjustice/%s:*", concat([for app in local.migration_apps_map : app.name], local.additional_repos_for_ecr))
  additional_permissions = data.aws_iam_policy_document.github_actions_iam_permissions_data_ecr.json
  role_name              = "github-actions-ecr-oidc"
  tags_common            = local.tags
  tags_prefix            = "data-platform"
  providers = {
    aws = aws.data
  }

}

data "aws_iam_policy_document" "github_actions_iam_permissions_data_ecr" {
  statement {
    sid       = "AllowDataECRPull"
    effect    = "Allow"
    resources = ["arn:aws:ecr:*:${local.accounts["data"]}:repository/*"]
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
  }

  statement {
    sid       = "AllowDataECRAuthorisation"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}


module "github-oidc-provider-sandbox" {

  source                 = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v2.1.0"
  github_repositories    = ["ministryofjustice/data-platform:*", "ministryofjustice/analytical-platform-iam:*"]
  additional_permissions = data.aws_iam_policy_document.github_actions_iam_permissions_sandbox.json
  role_name              = "github-actions-iam"
  tags_common            = local.tags
  tags_prefix            = "data-platform"
  providers = {
    aws = aws.sandbox
  }

}

data "aws_iam_policy_document" "github_actions_iam_permissions_sandbox" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    resources = [format("arn:aws:iam::%s:role/github-actions-infrastructure", local.accounts["sandbox"])]
    actions   = ["sts:AssumeRole"]
  }
  statement {
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]
  }

  statement {
    sid       = "AllowOIDCReadState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/*", "arn:aws:s3:::global-tf-state-aqsvzyd5u9/"]
    actions = ["s3:Get*",
    "s3:List*"]
  }

  statement {
    sid       = "AllowOIDCWriteState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
    actions = ["s3:PutObject",
    "s3:PutObjectAcl"]
  }
  statement {
    sid       = "AllowDynamoDBStateLocking"
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
  }
}

module "github-oidc-provider-data-engineering" {

  source                 = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v2.1.0"
  github_repositories    = ["ministryofjustice/data-platform:*", "ministryofjustice/analytical-platform-iam:*"]
  additional_permissions = data.aws_iam_policy_document.github_actions_iam_permissions_data_engineering.json
  role_name              = "github-actions-iam"
  tags_common            = local.tags
  tags_prefix            = "data-platform"
  providers = {
    aws = aws.data_engineering
  }

}

data "aws_iam_policy_document" "github_actions_iam_permissions_data_engineering" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    resources = [format("arn:aws:iam::%s:role/github-actions-infrastructure", local.accounts["data_engineering"])]
    actions   = ["sts:AssumeRole"]
  }
  statement {
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]
  }

  statement {
    sid       = "AllowOIDCReadState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/*", "arn:aws:s3:::global-tf-state-aqsvzyd5u9/"]
    actions = ["s3:Get*",
    "s3:List*"]
  }

  statement {
    sid       = "AllowOIDCWriteState"
    effect    = "Allow"
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
    actions = ["s3:PutObject",
    "s3:PutObjectAcl"]
  }
  statement {
    sid       = "AllowDynamoDBStateLocking"
    effect    = "Allow"
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
  }
}
