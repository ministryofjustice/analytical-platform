data "aws_iam_roles" "self-hosted-runner-roles" {
  provider   = aws.management
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "data-self-hosted-runner-roles" {
  provider   = aws.data
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "dev-self-hosted-runner-roles" {
  provider   = aws.dev
  name_regex = "github-actions-runner*|github-actions-self-hosted-runner"
}

data "aws_iam_roles" "analytical-platform-sso-admin-access-sandbox" {
  provider    = aws.sandbox
  name_regex  = "AWSReservedSSO_AdministratorAccess_.*"
  path_prefix = "/aws-reserved/sso.amazonaws.com/"
}

module "management-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name] if module.github_actions_roles != {} && contains(config.targets, "management")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.management
  }
}

module "data-assumable-role" {
  for_each               = local.deployment-roles
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = false
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    [module.github-oidc-provider.github_actions_role],
    [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "data")],
    [for role_name, config in local.oidc-roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "management") == "data_engineering" && contains(config.targets, "data")],
    [for role_name, config in local.oidc-roles : module.github_actions_roles_data[role_name].role if try(config.account, "management") == "data" && contains(config.targets, "data")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${local.accounts[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.self-hosted-runner-roles.arns, data.aws_iam_roles.data-self-hosted-runner-roles.arns, data.aws_iam_roles.dev-self-hosted-runner-roles.arns]))
  force_detach_policies = true
  role_name             = each.key
  role_description      = each.value.description
  role_requires_mfa     = "false"
  providers = {
    aws = aws.data
  }
}

module "data-engineering-assumable-role" {
  for_each               = local.deployment-roles
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = false
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    [module.github-oidc-provider.github_actions_role],
    [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "data_engineering")],
    [for role_name, config in local.oidc-roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "management") == "data_engineering" && contains(config.targets, "data_engineering")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${local.accounts[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.self-hosted-runner-roles.arns, data.aws_iam_roles.data-self-hosted-runner-roles.arns, data.aws_iam_roles.dev-self-hosted-runner-roles.arns]))
  force_detach_policies = true
  role_name             = each.key
  role_description      = each.value.description
  role_requires_mfa     = "false"
  providers = {
    aws = aws.data_engineering
  }
}

module "prod-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "prod")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.prod
  }
}

module "dev-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "dev")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.dev
  }
}

module "sandbox-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.analytical-platform-sso-admin-access-sandbox.arns),
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role, module.github-oidc-provider-sandbox.github_actions_role],                                                                                                                 # assumable both by the management iam role and the sandbox iam role
    [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && try(config.account, "management") == "management" && contains(config.targets, "sandbox")], # roles in management account that need to assume a role in the sandbox
    [for role_name, config in local.oidc-roles : module.github_actions_roles_sandbox[role_name].role if try(config.account, "management") == "sandbox" && contains(config.targets, "sandbox")],                                 # roles in sandbox account that need to assume a role in the sandbox
    [for role_name, config in local.oidc-roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "management") == "data_engineering" && contains(config.targets, "sandbox")]                # roles in data_engineering account that need to assume a role in the sandbox
  )
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.sandbox
  }
}

module "dev-data-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "dev_data")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.dev_data
  }
}


module "mi-dev-data-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "mi_dev")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.mi_dev
  }
}

module "landing-assumable-role" {
  source                 = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version                = "~> 5.11"
  allow_self_assume_role = true
  attach_admin_policy    = true
  create_role            = true
  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc-roles : module.github_actions_roles[role_name].role if contains(config.targets, "landing")])
  force_detach_policies = true
  role_name             = "github-actions-infrastructure"
  role_description      = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa     = "false"
  providers = {
    aws = aws.landing
  }
}