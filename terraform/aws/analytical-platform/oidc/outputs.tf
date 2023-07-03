# output "github-roles" {
#   value = {
#     for role, config in local.oidc-roles : module.github_actions_roles[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if module.github_actions_roles != {} && try(config.account, "management") == "management"
#   }
# }

# output "github-sandbox-roles" {
#   value = {
#     for role, config in local.oidc-roles : module.github_actions_roles_sandbox[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "sandbox"
#   }
# }

# output "github-data_engineering-roles" {
#   value = {
#     for role, config in local.oidc-roles : module.github_actions_roles_data_engineering[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "data_engineering"
#   }
# }

# output "github-data-roles" {
#   value = {
#     for role, config in local.oidc-roles : module.github_actions_roles_data[role].role => data.aws_iam_policy_document.github_actions_role_permissions[role].json if try(config.account, "management") == "data"
#   }
# }
