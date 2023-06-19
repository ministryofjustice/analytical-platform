data "aws_caller_identity" "current" {
  provider = aws.session-info
}

data "aws_iam_session_context" "whoami" {
  provider = aws.session-info
  arn      = data.aws_caller_identity.current.arn
}

data "aws_caller_identity" "data" {
  provider = aws.data
}

data "github_team" "migration_app_owner" {
  for_each = toset(local.unique_old_teams_names)
  provider = github.moj-analytical-services
  slug     = each.key
}

data "github_repository_teams" "migration_apps_repo_owners" {
  for_each = local.migration_apps_map
  provider = github.moj-analytical-services
  name     = each.value.source_repo_name
}

data "aws_secretsmanager_secret" "github_token" {
  provider = aws.management
  name     = "github-token"
}

data "aws_secretsmanager_secret_version" "github_token" {
  provider  = aws.management
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

# Application Migration (used to add APP_ROLE_ARN secret to app repos)

// Fetch Existing Roles
data "aws_iam_roles" "data_app_roles" {
  provider   = aws.data
  for_each   = local.migration_apps_map
  name_regex = format("alpha_app_%s$", each.key)
}

data "aws_iam_role" "app_role_details" {
  provider = aws.data
  for_each = data.aws_iam_roles.data_app_roles
  name     = one(each.value.names)
}

