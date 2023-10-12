data "aws_iam_policy_document" "github_oidc_role" {
  for_each = local.oidc_roles

  dynamic "statement" {
    for_each = length(each.value.targets) > 0 ? [1] : [0]

    content {
      sid     = "AllowOIDCToAssumeRoles"
      effect  = "Allow"
      actions = ["sts:AssumeRole"]
      resources = flatten([
        for target in each.value.targets : [
          "arn:aws:iam::${var.account_ids[target]}:role/github-actions-infrastructure",
          contains(["analytical-platform-data-production", "analytical-platform-data-engineering-production"], target) ? ["arn:aws:iam::${var.account_ids[target]}:role/data-engineering-infrastructure"] : []
        ]
      ])
    }
  }
  dynamic "statement" {
    for_each = each.value.stateConfig

    content {
      sid    = "AllowOIDCReadState"
      effect = "Allow"
      actions = [
        "s3:Get*",
        "s3:List*"
      ]
      resources = [
        "arn:aws:s3:::${statement.value.stateBucket}",
        "arn:aws:s3:::${statement.value.stateBucket}*"
      ]
    }
  }
  dynamic "statement" {
    for_each = each.value.stateConfig

    content {
      sid    = "AllowOIDCWriteState"
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:DeleteObject"
      ]
      resources = ["arn:aws:s3:::${statement.value.stateBucket}${statement.value.stateBucketKey}*"]
    }
  }
  dynamic "statement" {
    for_each = each.value.stateLockingDetails

    content {
      sid    = "AllowDynamoDBStateLocking"
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ]
      resources = ["${each.value.stateLockingDetails.dynamodbArn}${each.value.stateLockingDetails.dynamodbTableName}"]
    }
  }
  dynamic "statement" {
    for_each = try(each.value.ssmParameterConfig, {})

    content {
      sid    = "AllowSSMParameterRead"
      effect = "Allow"
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory",
        "ssm:GetParametersByPath"
      ]
      resources = formatlist("arn:aws:ssm:%s:%s:parameter/%s*", statement.value.ssmParameterRegion, var.account_ids[try(each.value.account, "analytical-platform-management-production")], statement.value.ssmParameterArnPrefixes)
    }
  }
  statement {
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]
  }
}

module "analytical_platform_data_engineering_production_github_oidc_role" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v3.0.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_oidc_role[each.key].json]
  github_repositories = each.value.repositories

  tags = var.tags
}

module "analytical_platform_data_engineering_sandbox_a_github_oidc_role" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-sandbox-a" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v3.0.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_oidc_role[each.key].json]
  github_repositories = each.value.repositories

  tags = var.tags
}

module "analytical_platform_data_production_github_oidc_role" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v3.0.0"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_oidc_role[each.key].json]
  github_repositories = each.value.repositories

  tags = var.tags
}

module "analytical_platform_management_production_github_oidc_role" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-management-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v3.1.0"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_oidc_role[each.key].json]
  github_repositories = each.value.repositories

  tags = var.tags
}


resource "aws_iam_role" "github_actions" {
  provider           = aws.analytical-platform-data-production
  name               = "github-actions-ecr-oidc"
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  version = "2012-10-17"

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.data_production.account_id}:oidc-provider/token.actions.githubusercontent.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = formatlist("*:*/%s:*", concat([for app in local.migration_apps_map : app.name], local.additional_repos_for_ecr))
    }

    condition {
      test     = "ForAllValues:StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ministryofjustice/*"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "read_only" {
  provider   = aws.analytical-platform-data-production
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Add actions missing from arn:aws:iam::aws:policy/ReadOnlyAccess
resource "aws_iam_policy" "extra_permissions" {
  provider    = aws.analytical-platform-data-production
  name        = aws_iam_role.github_actions.name
  path        = "/"
  description = "A policy for extra permissions for GitHub Actions"

  policy = data.aws_iam_policy_document.analytical_platform_data_production_github_oidc_provider.json
}

resource "aws_iam_role_policy_attachment" "extra_permissions" {
  provider   = aws.analytical-platform-data-production
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.extra_permissions.arn
}
