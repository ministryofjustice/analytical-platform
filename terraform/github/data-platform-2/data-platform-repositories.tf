locals {
  data_platform_repositories = {
    "data-platform" = {
      name            = "data-platform"
      description     = "Data Platform"
      topics          = ["ministryofjustice", "data-platform"]
      use_template    = false
      has_discussions = true
      has_projects    = true
      homepage_url    = "https://technical-documentation.data-platform.service.justice.gov.uk"
      pages_enabled   = true
      pages_configuration = {
        cname = "technical-documentation.data-platform.service.justice.gov.uk"
        source = {
          branch = "gh-pages"
          path   = "/docs"
        }
      }
      access = {
        admins      = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        maintainers = [module.data_platform_teams["data-platform-labs"].id]
        pushers     = [module.data_platform_team.id]
      }
    }
    "data-platform-products" = {
      name        = "data-platform-products"
      description = "Data Platform Products"
      topics      = ["ministryofjustice", "data-platform"]
      access = {
        admins      = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        maintainers = [module.data_platform_teams["data-platform-labs"].id]
        pushers     = [module.data_platform_team.id]
      }
    }
    "data-platform-support" = {
      name        = "data-platform-support"
      description = "Data Platform Support"
      topics      = ["ministryofjustice", "data-platform"]
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "data-platform-user-guidance" = {
      name          = "data-platform-user-guidance"
      description   = "Data Platform User Guidance"
      topics        = ["ministryofjustice", "data-platform"]
      pages_enabled = true
      pages_configuration = {
        cname = "data-platform.service.justice.gov.uk"
        source = {
          branch = "main"
          path   = "/"
        }
      }
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
  }
}

module "data_platform_repositories" {
  source = "./modules/repository"

  for_each = { for repository in local.data_platform_repositories : repository.name => repository }

  name        = each.value.name
  description = each.value.description
  topics      = lookup(each.value, "topics", [])
  visibility  = lookup(each.value, "visibility", "public")

  archived           = lookup(each.value, "archived", false)
  archive_on_destroy = lookup(each.value, "archive_on_destroy", true)

  use_template         = lookup(each.value, "use_template", true)
  has_discussions      = lookup(each.value, "has_discussions", false)
  has_downloads        = lookup(each.value, "has_downloads", false)
  has_issues           = lookup(each.value, "has_issues", true)
  has_projects         = lookup(each.value, "has_projects", false)
  has_wiki             = lookup(each.value, "has_wiki", false)
  homepage_url         = lookup(each.value, "homepage_url", "https://data-platform.service.justice.gov.uk")
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

  access = lookup(each.value, "access", null)
}
