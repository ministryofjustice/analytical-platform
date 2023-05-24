data "aws_iam_policy_document" "github_actions_role_permissions" {
  for_each = local.oidc-roles
  dynamic "statement" {
    for_each = length(each.value.targets) > 0 ? [1] : [0]
    content {
      sid    = "AllowOIDCToAssumeRoles"
      effect = "Allow"
      resources = flatten([
        for target in each.value.targets : [
          "arn:aws:iam::${local.accounts[target]}:role/github-actions-infrastructure",
          contains(["data", "data_engineering"], target) ? ["arn:aws:iam::${local.accounts[target]}:role/data-engineering-infrastructure"] : []
      ]])
      actions = ["sts:AssumeRole"]
    }
  }
  statement {
    sid       = "AllowOIDCToDecryptKMS"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["kms:Decrypt"]
  }
  dynamic "statement" {
    for_each = each.value.stateConfig
    content {
      sid       = "AllowOIDCReadState"
      effect    = "Allow"
      resources = ["arn:aws:s3:::${statement.value.stateBucket}*", "arn:aws:s3:::${statement.value.stateBucket}"]
      actions = ["s3:Get*",
      "s3:List*"]
    }
  }
  dynamic "statement" {
    for_each = each.value.stateConfig

    content {
      sid       = "AllowOIDCWriteState"
      effect    = "Allow"
      resources = ["arn:aws:s3:::${statement.value.stateBucket}${statement.value.stateBucketKey}*"]
      actions = ["s3:PutObject",
        "s3:PutObjectAcl",
      "s3:DeleteObject"]
    }
  }
  dynamic "statement" {
    for_each = each.value.stateLockingDetails
    content {
      sid       = "AllowDynamoDBStateLocking"
      effect    = "Allow"
      resources = ["${each.value.stateLockingDetails.dynamodbArn}${each.value.stateLockingDetails.dynamodbTableName}"]
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ]
    }
  }
  dynamic "statement" {
    for_each = try(each.value.ssmParameterConfig, {})
    content {
      sid       = "AllowSSMParameterRead"
      effect    = "Allow"
      resources = formatlist("arn:aws:ssm:%s:%s:parameter/%s*", statement.value.ssmParameterRegion, local.accounts[try(each.value.account, "management")], statement.value.ssmParameterArnPrefixes)
      actions = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParameterHistory",
        "ssm:GetParametersByPath"
      ]
    }
  }
}

module "github_actions_roles" {
  for_each            = { for role, config in local.oidc-roles : role => config if try(config.account, "management") == "management" }
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v1.0.0"
  github_repositories = each.value.repositories
  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  tags                = local.tags
  providers = {
    aws = aws.management
  }
}

module "github_actions_roles_sandbox" {
  for_each            = { for role, config in local.oidc-roles : role => config if try(config.account, "management") == "sandbox" }
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v1.0.0"
  github_repositories = each.value.repositories
  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  tags                = local.tags
  providers = {
    aws = aws.sandbox
  }
}

module "github_actions_roles_data_engineering" {
  for_each            = { for role, config in local.oidc-roles : role => config if try(config.account, "management") == "data_engineering" }
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v1.0.0"
  github_repositories = each.value.repositories
  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  tags                = local.tags
  providers = {
    aws = aws.data_engineering
  }
}

module "github_actions_roles_data" {
  for_each            = { for role, config in local.oidc-roles : role => config if try(config.account, "management") == "data" }
  source              = "github.com/ministryofjustice/modernisation-platform-github-oidc-role?ref=v1.0.0"
  github_repositories = each.value.repositories
  role_name           = "github-${each.key}"
  policy_jsons        = [data.aws_iam_policy_document.github_actions_role_permissions[each.key].json]
  tags                = local.tags
  providers = {
    aws = aws.data
  }
}

output "github-roles" {
  value = {
    for role, config in local.oidc-roles : module.github_actions_roles[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if module.github_actions_roles != {} && try(config.account, "management") == "management"
  }
}

output "github-sandbox-roles" {
  value = {
    for role, config in local.oidc-roles : module.github_actions_roles_sandbox[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "sandbox"
  }
}

output "github-data_engineering-roles" {
  value = {
    for role, config in local.oidc-roles : module.github_actions_roles_data_engineering[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "data_engineering"
  }
}

output "github-data-roles" {
  value = {
    for role, config in local.oidc-roles : module.github_actions_roles_data[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "data"
  }
}
