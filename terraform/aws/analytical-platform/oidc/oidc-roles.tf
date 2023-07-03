data "aws_iam_policy_document" "github_actions_role_permissions" {
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

module "github_actions_roles" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-management-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v2.0.0"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  github_repositories = each.value.repositories

  tags = local.tags
}

module "github_actions_roles_sandbox" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-sandbox-a" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v2.0.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  github_repositories = each.value.repositories

  tags = local.tags
}

module "github_actions_roles_data_engineering" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v2.0.0"

  providers = {
    aws = aws.analytical-platform-data-engineering-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  github_repositories = each.value.repositories

  tags = local.tags
}

module "github_actions_roles_data" {
  for_each = { for role, config in local.oidc_roles : role => config if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-production" }

  source = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v2.0.0"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  github_repositories = each.value.repositories

  tags = local.tags
}
