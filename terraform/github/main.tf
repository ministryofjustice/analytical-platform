# Repositories
module "core" {
  for_each     = { for repo in local.core_repos : repo.name => repo }
  source       = "./modules/repository"
  name         = each.key
  type         = "core"
  description  = each.value.description
  visibility   = "internal"
  homepage_url = "https://ministryofjustice.github.io/ap-tech-docs"
  topics = [
"architecture-decisions",
"aws",
"documentation",
"kops",
"kubernetes",
"terraform"
  ]
}

module "data-platform" {
  source                 = "./modules/repository"
  name                   = "data-platform"
  type                   = "core"
  description            = "Core Infrastructure Repo for Data Platform"
  homepage_url           = "https://github.com/ministryofjustice/data-platform/blob/main/architecture/decision/README.md"
  require_signed_commits = true
  topics = [
    "architecture-decisions",
    "aws",
    "documentation"
  ]

  secrets = {
    # Repository GitHub token for the CI/CD user
    REPOSITORY_GITHUB_TOKEN = "This needs to be manually set in GitHub."
    # Teams GitHub token for the CI/CD user
    TEAMS_GITHUB_TOKEN = "This needs to be manually set in GitHub."
    # Management Account ID
    MANAGEMENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
}

# Everyone, with access to the above repositories
module "core-team" {
  source      = "./modules/team"
  name        = "analytics-hq"
  description = "Analytical Platform team"
  repositories = concat(
    [for repo in module.core : repo.repository.name],
  [module.data-platform.repository.name])

  maintainers = local.maintainers
  members     = local.all_members
  ci          = local.ci_users
}

module "data-platform-tech-archs-team" {
  source      = "./modules/team"
  name        = "data-tech-archs"
  description = "Data Platform Technical Architects"
  repositories = [
    module.data-platform.repository.name
  ]

  maintainers = local.tech_archs_maintainers
  members     = local.tech_archs
  ci          = local.ci_users
}

# People who need full AWS access
module "aws-team" {
  source      = "./modules/team"
  name        = "analytical-platform"
  description = "Analytical Platform team: people who get Administrator AWS access"

  maintainers = local.maintainers
  members     = local.engineers
  ci          = local.ci_users

  parent_team_id = module.core-team.team_id
}

# Data Engineering Team

module "data-engineering-team" {
source      = "./modules/team"
name        = "data-engineering"
description = "Data Engineering team"

maintainers = local.data_engineering_maintainers
members     = local.all_members_data_engineers
ci          = local.ci_users
}
