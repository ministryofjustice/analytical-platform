module "analytical_platform_data_development_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "analytical-platform-data-development")])
}

module "analytical_platform_data_engineering_production_assumable_role" {
  for_each = local.deployment_roles

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "analytical-platform-data-engineering-production")],
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-engineering-production")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${var.account_ids[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns, data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns, data.aws_iam_roles.analytical_platform_development_runner_roles.arns]))
}

module "analytical_platform_data_engineering_sandbox_a_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_data_engineering_sandbox_sso_administrator_access_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role, module.analytical_platform_data_engineering_sandbox_a_github_oidc_provider.github_actions_role],                                                                                                                                                                                                                                     # assumable both by the management iam role and the sandbox iam role
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && try(config.account, "aws.analytical-platform-management-production") == "aws.analytical-platform-management-production" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")], # roles in management account that need to assume a role in the sandbox
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_sandbox_a_github_oidc_role[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-sandbox-a" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")],                                                                                  # roles in sandbox account that need to assume a role in the sandbox
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-engineering-sandbox-a")]                                                                                 # roles in data_engineering account that need to assume a role in the sandbox
  )
}

module "analytical_platform_data_production_assumable_role" {
  for_each = local.deployment_roles

  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "analytical-platform-data-engineering-production")],
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-engineering-production" && contains(config.targets, "analytical-platform-data-production")],
    [for role_name, config in local.oidc_roles : module.analytical_platform_data_production_github_oidc_role[role_name].role if try(config.account, "aws.analytical-platform-management-production") == "analytical-platform-data-production" && contains(config.targets, "analytical-platform-data-production")],
    each.value.trusts != {} ? [for acct in each.value.trusts.accounts : "arn:aws:iam::${var.account_ids[acct]}:role/${each.value.trusts.name}"] :
  flatten([data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns, data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns, data.aws_iam_roles.analytical_platform_development_runner_roles.arns]))
}

module "analytical_platform_development_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "analytical-platform-development")])
}

module "analytical_platform_landing_production_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if contains(config.targets, "analytical-platform-landing-production")])
}

module "analytical_platform_management_production_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name] if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "aws.analytical-platform-management-production")])
}

module "analytical_platform_production_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "analytical-platform-production")])
}

module "mi_platform_development_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "5.25.0"

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
    tolist(data.aws_iam_roles.analytical_platform_management_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_data_production_runner_roles.arns),
    tolist(data.aws_iam_roles.analytical_platform_development_runner_roles.arns),
    [module.analytical_platform_management_production_github_oidc_provider.github_actions_role],
  [for role_name, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role_name].role if module.analytical_platform_data_engineering_production_github_oidc_role != {} && contains(config.targets, "mi-platform-development")])
}
