output "analytical_platform_data_engineering_production_github_oidc_roles" {
  value = {
    for role, config in local.oidc_roles : module.analytical_platform_data_engineering_production_github_oidc_role[role].role => data.aws_iam_policy_document.github_oidc_role[role].json if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-production"
  }
}

output "analytical_platform_data_engineering_sandbox_a_github_oidc_roles" {
  value = {
    for role, config in local.oidc_roles : module.analytical_platform_data_engineering_sandbox_a_github_oidc_role[role].role => data.aws_iam_policy_document.github_oidc_role[role].json if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-engineering-sandbox-a"
  }
}

output "analytical_platform_data_production_github_oidc_roles" {
  value = {
    for role, config in local.oidc_roles : module.analytical_platform_data_production_github_oidc_role[role].role => data.aws_iam_policy_document.github_oidc_role[role].json if try(config.account, "analytical-platform-management-production") == "analytical-platform-data-production"
  }
}

output "analytical_platform_management_production_github_oidc_roles" {
  value = {
    for role, config in local.oidc_roles : module.analytical_platform_management_production_github_oidc_role[role].role => data.aws_iam_policy_document.github_oidc_role[role].json if module.analytical_platform_management_production_github_oidc_role != {} && try(config.account, "analytical-platform-management-production") == "analytical-platform-management-production"
  }
}
