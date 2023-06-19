# Repositories
module "core" {
  for_each     = { for repo in local.core_repos : repo.name => repo }
  source       = "../modules/repository"
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
  for_each               = { for repo in local.data_platform_repos : repo.name => repo }
  source                 = "../modules/repository"
  name                   = each.key
  type                   = "core"
  description            = each.value.description
  homepage_url           = "https://technical-documentation.data-platform.service.justice.gov.uk/"
  require_signed_commits = false # disabling until we amend code-formatter to use signed commits
  topics = [
    "architecture-decisions",
    "aws",
    "documentation"
  ]

  secrets = {
    # Management Account ID
    MANAGEMENT_ACCOUNT_ID = data.aws_caller_identity.current.account_id
  }
}

module "data-platform-app-template" {
  source      = "../modules/repository"
  name        = "data-platform-app-template"
  description = "Template repository for data-platform apps"
  visibility  = "internal"
  type        = "template"
  topics = [
    "data-platform-apps",
    "data-platform-apps-and-tools",
    "template",
  ]
}

# Everyone, with access to the above repositories
module "core-team" {
  source      = "../modules/team"
  name        = "analytics-hq"
  description = "Analytical Platform team"
  repositories = concat(
    [for repo in module.core : repo.repository.name],
    [for repo in module.data-platform : repo.repository.name],
    data.github_repositories.app_repositories.names,
    [module.data-platform-app-template.repository.name]
  )

  maintainers = local.maintainers
  members     = local.all_members
  ci          = local.ci_users
}

module "data-platform-tech-archs-team" {
  source       = "../modules/team"
  name         = "data-tech-archs"
  description  = "Data Platform Technical Architects"
  repositories = [for repo in module.data-platform : repo.repository.name]

  maintainers = local.tech_archs_maintainers
  members     = local.tech_archs
  ci          = local.ci_users
}

# People who need full AWS access
module "aws-team" {
  source      = "../modules/team"
  name        = "analytical-platform"
  description = "Analytical Platform team: people who get Administrator AWS access"

  maintainers = local.maintainers
  members     = local.engineers
  ci          = local.ci_users

  parent_team_id = module.core-team.team_id
}

# Data Engineering Team

module "data-engineering-team" {
  source      = "../modules/team"
  name        = "data-engineering"
  description = "Data Engineering team with Sandbox Access"

  maintainers = local.data_engineering_maintainers
  members     = local.all_members_data_engineers
  ci          = local.ci_users
}

# Data Engineering AWS Team
module "data-engineering-aws-team" {
  source      = "../modules/team"
  name        = "data-engineering-aws"
  description = "Data Engineering team with Environment Access"

  maintainers    = local.data_engineering_maintainers
  members        = concat(local.data_engineering_aws_members, local.data_engineering_maintainers)
  ci             = local.ci_users
  parent_team_id = module.data-engineering-team.team_id
}

# Allow data engineering to raise PRs in Data Platform repos
module "contributor-access" {
  for_each          = toset([for repo in module.data-platform : repo.repository.name])
  source            = "../modules/contributor"
  application_teams = ["data-engineering"]
  repository_id     = each.key
}

# Data Platform Core Infrastructure Team
module "data_platform_core_infrastructure_team" {
  source       = "../modules/team"
  name         = "data-platform-core-infra"
  description  = "Data Platform Core Infrastructure team"
  repositories = [for repo in module.data-platform : repo.repository.name]

  maintainers = local.data_platform_core_infrastructure_maintainers
  members     = local.all_members_data_platform_core_infrastructure
  ci          = local.ci_users
}

# Data Platform Labs Team
module "data_platform_labs_team" {
  source       = "../modules/team"
  name         = "data-platform-labs"
  description  = "Data Platform Labs team"
  repositories = [for repo in module.data-platform : repo.repository.name]

  maintainers = local.data_platform_labs_maintainers
  members     = local.all_members_data_platform_labs
  ci          = local.ci_users
}

# Data Platform Security Auditor Team
module "data_platform_security_auditor_team" {
  source      = "../modules/team"
  name        = "data-platform-security-and-auditors"
  description = "Data Platform Security and Auditor Team"
  maintainers = local.data_platform_security_auditor_members
  members     = local.data_platform_security_auditor_members
  ci          = local.ci_users
}

# Data Platform Limited AWS Access Team
module "data_platform_engineering_developer_team" {
  source      = "../modules/team"
  name        = "data-engineering-aws-developers"
  description = "Data Engineering AWS (Developer Access)"
  maintainers = local.maintainers
  members     = distinct(concat(local.data_engineering_aws_developer_members, local.maintainers))
  ci          = local.ci_users
}
