# Repositories

module "data-platform-apps" {
  for_each           = local.migration_apps_map
  source             = "../modules/repository"
  name               = each.key
  type               = "app"
  description        = each.value.description
  homepage_url       = "https://github.com/ministryofjustice/data-platform/blob/main/architecture/decision/README.md"
  template_repo      = "data-platform-app-template"
  visibility         = "internal"
  archive_on_destroy = false
  environments       = ["prod", "dev"]
  topics = [
    "data-platform-apps",
    "data-platform-apps-and-tools",
    "aws",
    "helm",
    "cloud-platform"
  ]
  secrets = {
    # Management Account ID
    MANAGEMENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id

    # Data Account ID
    DATA_ACCOUNT_ID = data.aws_caller_identity.data.account_id

    # Existing App Role ARN
    APP_ROLE_ARN = data.aws_iam_role.app_role_details[each.key].arn
  }

}

# Data Platform Apps Teams

module "migration_apps_teams" {
  for_each    = local.team_repo_map
  source      = "../modules/team"
  name        = each.key
  description = data.github_team.migration_app_owner[each.key].description

  maintainers  = data.github_team.migration_app_owner[each.key].members
  members      = data.github_team.migration_app_owner[each.key].members
  repositories = each.value
  ci           = local.ci_users
}
