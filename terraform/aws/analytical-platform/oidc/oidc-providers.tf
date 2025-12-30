data "aws_iam_policy_document" "analytical_platform_data_engineering_production_github_oidc_provider" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [format("arn:aws:iam::%s:role/github-actions-infrastructure", var.account_ids["analytical-platform-data-engineering-production"])]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    sid    = "AllowOIDCReadState"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/*", "arn:aws:s3:::global-tf-state-aqsvzyd5u9/"]
  }
  statement {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
    sid    = "AllowOIDCWriteState"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
  }
  statement {
    sid    = "AllowDynamoDBStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
  }
}

module "analytical_platform_data_engineering_production_github_oidc_provider" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v3.1.1"

  providers = {
    aws = aws.analytical-platform-data-engineering-production
  }

  role_name              = "github-actions-iam"
  additional_permissions = data.aws_iam_policy_document.analytical_platform_data_engineering_production_github_oidc_provider.json
  github_repositories = [
    "ministryofjustice/data-platform:*",
    "ministryofjustice/analytical-platform-iam:*"
  ]

  tags_prefix = "data-platform"
  tags_common = var.tags
}

data "aws_iam_policy_document" "analytical_platform_data_engineering_sandbox_a_github_oidc_provider" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [format("arn:aws:iam::%s:role/github-actions-infrastructure", var.account_ids["analytical-platform-data-engineering-sandbox-a"])]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    sid    = "AllowOIDCReadState"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/*", "arn:aws:s3:::global-tf-state-aqsvzyd5u9/"]
  }
  statement {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
    sid    = "AllowOIDCWriteState"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
  }
  statement {
    sid    = "AllowDynamoDBStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
  }
}

module "analytical_platform_data_engineering_sandbox_a_github_oidc_provider" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v3.1.1"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a
  }

  role_name              = "github-actions-iam"
  additional_permissions = data.aws_iam_policy_document.analytical_platform_data_engineering_sandbox_a_github_oidc_provider.json
  github_repositories = [
    "ministryofjustice/data-platform:*",
    "ministryofjustice/analytical-platform-iam:*"
  ]

  tags_prefix = "data-platform"
  tags_common = var.tags
}

data "aws_iam_policy_document" "analytical_platform_data_production_github_oidc_provider" {
  statement {
    sid    = "AllowDataECRPull"
    effect = "Allow"
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = ["arn:aws:ecr:*:${var.account_ids["analytical-platform-data-production"]}:repository/*"]
  }
  statement {
    sid       = "AllowDataECRAuthorisation"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
}

module "analytical_platform_data_production_github_oidc_provider" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v4.2.0"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  role_name              = "github-actions-ecr-oidc-dummy"
  additional_permissions = data.aws_iam_policy_document.analytical_platform_data_production_github_oidc_provider.json
  github_repositories = [
    "ministryofjustice/data-platform-dummy-repo:*",
    "ministryofjustice/ap-rshiny-notesbook:*"
  ]

  tags_prefix = "data-platform"
  tags_common = var.tags
}

data "aws_iam_policy_document" "analytical_platform_management_production_github_oidc_provider" {
  statement {
    sid       = "AllowOIDCToAssumeRoles"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = formatlist("arn:aws:iam::%s:role/github-actions-infrastructure", values(var.account_ids))
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    #checkov:skip=CKV_AWS_356: skip requires access to multiple resources
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = ["*"]
  }
  #tfsec:ignore:avd-aws-0057:needs to access multiple resources
  statement {
    sid    = "AllowOIDCReadState"
    effect = "Allow"
    actions = [
      "s3:Get*",
      "s3:List*"
    ]
    resources = [
      "arn:aws:s3:::global-tf-state-aqsvzyd5u9/",
      "arn:aws:s3:::global-tf-state-aqsvzyd5u9/*"
    ]
  }
  statement {
    #checkov:skip=CKV_AWS_111: skip requires access to multiple resources
    sid    = "AllowOIDCWriteState"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["arn:aws:s3:::global-tf-state-aqsvzyd5u9/iam/*"]
  }
  statement {
    sid    = "AllowDynamoDBStateLocking"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = ["arn:aws:dynamodb:eu-west-2:042130406152:table/global-tf-state-aqsvzyd5u9-locks"]
  }
}

module "analytical_platform_management_production_github_oidc_provider" {
  #checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-provider?ref=v3.1.1"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  role_name              = "github-actions-iam"
  additional_permissions = data.aws_iam_policy_document.analytical_platform_management_production_github_oidc_provider.json
  github_repositories = [
    "ministryofjustice/data-platform:*",
    "ministryofjustice/analytical-platform-iam:*"
  ]

  tags_prefix = "data-platform"
  tags_common = var.tags
}
