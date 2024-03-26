locals {
  data_catalogue_repositories = {
    "data-catalogue" = {
      name        = "data-catalogue"
      description = "Data catalogue"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      has_discussions = true
      has_projects    = true
      homepage_url    = "https://user-guide.data-catalogue.service.justice.gov.uk"

      access = {
        admins = [module.data_platform_teams["data-catalogue"].id]
        pushers = [
          module.data_platform_team.id,
          data.github_team.data_engineering.id
        ]
      }
    }
    "find-moj-data" = {
      name        = "find-moj-data"
      description = "Find MOJ data service"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      template_repository = "data-platform-app-template"
      has_projects        = true
      homepage_url        = null

      access = {
        admins  = [module.data_platform_teams["data-catalogue"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "datahub-custom-api-source" = {
      name        = "datahub-custom-api-source"
      description = "Custom ingestion source for Datahub to consume from https://data.justice.gov.uk/api"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      has_projects = true
      homepage_url = null

      access = {
        admins  = [module.data_platform_teams["data-catalogue"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "datahub-catalogue-metadata" = {
      name        = "data-catalogue-metadata"
      description = "Data Catalogue Metadata"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]
      visibility  = "internal"

      has_projects = true
      homepage_url = null

      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"

      access = {
        admins = [module.data_platform_teams["data-catalogue"].id]
        pushers = [
          module.data_platform_team.id,
          data.github_team.data_engineering.id
        ]
      }
    }
    "datahub-custom-domain-source" = {
      name        = "datahub-custom-domain-source"
      description = "Custom ingestion source for Datahub to consume from https://data.justice.gov.uk/api"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      has_projects = true
      homepage_url = null

      access = {
        admins  = [module.data_platform_teams["data-catalogue"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "data-catalogue-user-guide" = {
      name        = "data-catalogue-user-guide"
      description = "Data Catalogue User Guide"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      has_issues   = true
      homepage_url = "https://user-guide.data-catalogue.service.justice.gov.uk"

      template_repository = "template-documentation-site"

      pages_enabled = true
      pages_configuration = {
        cname = "user-guide.data-catalogue.service.justice.gov.uk"
        source = {
          branch = "main"
          path   = "/"
        }
      }
      access = {
        admins  = [module.data_platform_teams["data-catalogue"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "data-catalogue-runbooks" = {
      name        = "data-catalogue-runbooks"
      description = "Data Catalogue Runbooks"
      topics      = ["ministryofjustice", "data-platform", "data-catalogue"]

      has_issues   = true
      homepage_url = "https://runbooks.data-catalogue.service.justice.gov.uk"

      template_repository = "template-documentation-site"

      pages_enabled = true
      pages_configuration = {
        cname = "runbooks.data-catalogue.service.justice.gov.uk"
        source = {
          branch = "main"
          path   = "/"
        }
      }
      access = {
        admins  = [module.data_platform_teams["data-catalogue"].id]
        pushers = [module.data_platform_team.id]
      }
    }
  }
}

module "data_catalogue_repositories" {
  source = "./modules/repository"

  for_each = { for repository in local.data_catalogue_repositories : repository.name => repository }

  name        = each.value.name
  description = each.value.description
  topics      = lookup(each.value, "topics", [])
  visibility  = lookup(each.value, "visibility", "public")

  archived           = lookup(each.value, "archived", false)
  archive_on_destroy = lookup(each.value, "archive_on_destroy", true)

  is_template = lookup(each.value, "is_template", false)

  use_template         = lookup(each.value, "use_template", true)
  template_repository  = lookup(each.value, "template_repository", "template-repository")
  has_discussions      = lookup(each.value, "has_discussions", false)
  has_downloads        = lookup(each.value, "has_downloads", false)
  has_issues           = lookup(each.value, "has_issues", true)
  has_projects         = lookup(each.value, "has_projects", false)
  has_wiki             = lookup(each.value, "has_wiki", false)
  homepage_url         = lookup(each.value, "homepage_url", "https://data-catalogue.service.justice.gov.uk")
  vulnerability_alerts = lookup(each.value, "vulnerability_alerts", true)

  auto_init = lookup(each.value, "auto_init", true)

  allow_merge_commit   = lookup(each.value, "allow_merge_commit", false)
  merge_commit_title   = lookup(each.value, "merge_commit_title", "MERGE_MESSAGE")
  merge_commit_message = lookup(each.value, "merge_commit_message", "PR_TITLE")

  allow_squash_merge          = lookup(each.value, "allow_squash_merge", true)
  squash_merge_commit_title   = lookup(each.value, "squash_merge_commit_title", "PR_TITLE")
  squash_merge_commit_message = lookup(each.value, "squash_merge_commit_message", "COMMIT_MESSAGES")

  allow_update_branch    = lookup(each.value, "allow_update_branch", true)
  allow_auto_merge       = lookup(each.value, "allow_auto_merge", false)
  allow_rebase_merge     = lookup(each.value, "allow_rebase_merge", true)
  delete_branch_on_merge = lookup(each.value, "delete_branch_on_merge", true)

  pages_enabled       = lookup(each.value, "pages_enabled", false)
  pages_configuration = lookup(each.value, "pages_configuration", null)

  advanced_security_status               = lookup(each.value, "advanced_security_status", "enabled")
  secret_scanning_status                 = lookup(each.value, "secret_scanning_status", "enabled")
  secret_scanning_push_protection_status = lookup(each.value, "secret_scanning_push_protection_status", "enabled")

  dependabot_security_updates_enabled = lookup(each.value, "dependabot_security_updates_enabled", true)

  branch_protection_pattern                                                       = lookup(each.value, "branch_protection_pattern", "main")
  branch_protection_allows_deletions                                              = lookup(each.value, "branch_protection_allows_deletions", false)
  branch_protection_enforce_admins                                                = lookup(each.value, "branch_protection_enforce_admins", true)
  branch_protection_force_push_bypassers                                          = lookup(each.value, "branch_protection_force_push_bypassers", [])
  branch_protection_require_signed_commits                                        = lookup(each.value, "branch_protection_require_signed_commits", true)
  branch_protection_required_linear_history                                       = lookup(each.value, "branch_protection_required_linear_history", false)
  branch_protection_require_conversation_resolution                               = lookup(each.value, "branch_protection_require_conversation_resolution", true)
  branch_protection_allows_force_pushes                                           = lookup(each.value, "branch_protection_allows_force_pushes", false)
  branch_protection_lock_branch                                                   = lookup(each.value, "branch_protection_lock_branch", false)
  branch_protection_required_pull_request_reviews_dismiss_stale_reviews           = lookup(each.value, "branch_protection_required_pull_request_reviews_dismiss_stale_reviews", true)
  branch_protection_required_pull_request_reviews_restrict_dismissals             = lookup(each.value, "branch_protection_required_pull_request_reviews_restrict_dismissals", false)
  branch_protection_required_pull_request_reviews_dismissal_restrictions          = lookup(each.value, "branch_protection_required_pull_request_reviews_dismissal_restrictions", [])
  branch_protection_required_pull_request_reviews_pull_request_bypassers          = lookup(each.value, "branch_protection_required_pull_request_reviews_pull_request_bypassers", [])
  branch_protection_required_pull_request_reviews_require_code_owner_reviews      = lookup(each.value, "branch_protection_required_pull_request_reviews_require_code_owner_reviews", true)
  branch_protection_required_pull_request_reviews_require_last_push_approval      = lookup(each.value, "branch_protection_required_pull_request_reviews_require_last_push_approval", true)
  branch_protection_required_pull_request_reviews_required_approving_review_count = lookup(each.value, "branch_protection_required_pull_request_reviews_required_approving_review_count", 1)
  branch_protection_required_status_checks_strict                                 = lookup(each.value, "branch_protection_required_status_checks_strict", true)
  branch_protection_required_status_checks_contexts                               = lookup(each.value, "branch_protection_required_status_checks_contexts", [])

  access = lookup(each.value, "access", null)
}
