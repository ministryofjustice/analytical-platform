module "management-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-management-production
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name] if module.github_actions_roles != {} && contains(config.targets, "aws.analytical-platform-management-production")])
}

module "data-assumable-role" {
  for_each = local.deployment-roles

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-data-production
  }

  create_role = true

  role_name         = each.key
  role_description  = each.value.description
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = false
  force_detach_policies  = true

  trusted_role_arns = concat(
    [module.github-oidc-provider.github_actions_role],
    [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "analytical-platform-data-production")],
    [for role_name, config in local.oidc_roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-production")],
    [for role_name, config in local.oidc_roles : module.github_actions_roles_data[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-production" && contains(config.targets, "analytical-platform-data-production")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${var.account_ids[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.self-hosted-runner-roles.arns, data.aws_iam_roles.data-self-hosted-runner-roles.arns, data.aws_iam_roles.dev-self-hosted-runner-roles.arns]))
}

module "data-engineering-assumable-role" {
  for_each = local.deployment-roles

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-data-engineering-production
  }

  create_role = true

  role_name         = each.key
  role_description  = each.value.description
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = false
  force_detach_policies  = true

  trusted_role_arns = concat(
    [module.github-oidc-provider.github_actions_role],
    [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "analytical-platform-data-engineering-production")],
    [for role_name, config in local.oidc_roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-engineering-production")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${var.account_ids[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.self-hosted-runner-roles.arns, data.aws_iam_roles.data-self-hosted-runner-roles.arns, data.aws_iam_roles.dev-self-hosted-runner-roles.arns]))
}

module "prod-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-production
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "prod")])
}

module "dev-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-development
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "dev")])
}

module "sandbox-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-data-engineering-sandbox-a
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.analytical-platform-sso-admin-access-sandbox.arns),
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role, module.github-oidc-provider-sandbox.github_actions_role],                                                                                                                                                                                                                              # assumable both by the management iam role and the sandbox iam role
    [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && try(config.account, "aws.analytical-platform-management-production") == "aws.analytical-platform-management-production" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")], # roles in management account that need to assume a role in the sandbox
    [for role_name, config in local.oidc_roles : module.github_actions_roles_sandbox[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-sandbox-a" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")],                             # roles in sandbox account that need to assume a role in the sandbox
    [for role_name, config in local.oidc_roles : module.github_actions_roles_data_engineering[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")]                    # roles in data_engineering account that need to assume a role in the sandbox
  )
}

module "dev-data-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-data-development
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "dev_data")])
}

module "mi-dev-data-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.mi-platform-development
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if module.github_actions_roles != {} && contains(config.targets, "mi_dev")])
}

module "landing-assumable-role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 5.11"

  providers = {
    aws = aws.analytical-platform-landing-production
  }

  create_role = true

  role_name         = "github-actions-infrastructure"
  role_description  = "Allows GitHub Actions and self-hosted runners to administer this account"
  role_requires_mfa = "false"

  attach_admin_policy    = true
  allow_self_assume_role = true
  force_detach_policies  = true

  trusted_role_arns = concat(
    tolist(data.aws_iam_roles.self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.data-self-hosted-runner-roles.arns),
    tolist(data.aws_iam_roles.dev-self-hosted-runner-roles.arns),
    [module.github-oidc-provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.github_actions_roles[role_name].role if contains(config.targets, "landing")])
}
