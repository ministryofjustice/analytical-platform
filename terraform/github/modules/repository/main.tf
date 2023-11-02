#tfsec:ignore:AVD-GIT-0001:Ministry of Justice follow GOV.UK Service Manual guidance on coding in the open (https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable)
resource "github_repository" "this" {
  #checkov:skip=CKV_GIT_1:Ministry of Justice follow GOV.UK Service Manual guidance on coding in the open (https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable)

  name        = var.name
  description = join(" • ", [var.description, "This repository is defined and managed in Terraform"])
  topics      = var.topics
  visibility  = var.visibility

  archived           = var.archived
  archive_on_destroy = var.archive_on_destroy

  is_template = var.is_template

  dynamic "template" {
    for_each = var.use_template ? [1] : []
    content {
      owner      = "ministryofjustice"
      repository = var.template_repository
    }
  }

  has_discussions      = var.has_discussions
  has_downloads        = var.has_downloads
  has_issues           = var.has_issues
  has_projects         = var.has_projects
  has_wiki             = var.has_wiki
  homepage_url         = var.homepage_url
  vulnerability_alerts = var.vulnerability_alerts

  auto_init = var.auto_init

  allow_merge_commit   = var.allow_merge_commit
  merge_commit_title   = var.merge_commit_title
  merge_commit_message = var.merge_commit_message

  allow_squash_merge          = var.allow_squash_merge
  squash_merge_commit_title   = var.squash_merge_commit_title
  squash_merge_commit_message = var.squash_merge_commit_message

  allow_update_branch    = var.allow_update_branch
  allow_auto_merge       = var.allow_auto_merge
  allow_rebase_merge     = var.allow_rebase_merge
  delete_branch_on_merge = var.delete_branch_on_merge

  dynamic "pages" {
    for_each = var.pages_enabled ? [1] : []
    content {
      build_type = "workflow"
      cname      = var.pages_configuration.cname
      source {
        branch = var.pages_configuration.source.branch
        path   = var.pages_configuration.source.path
      }
    }
  }

  security_and_analysis {
    dynamic "advanced_security" {
      for_each = var.visibility == "private" || var.visibility == "internal" ? [1] : []
      content {
        status = var.advanced_security_status
      }
    }

    secret_scanning {
      status = var.secret_scanning_status
    }

    secret_scanning_push_protection {
      status = var.secret_scanning_push_protection_status
    }
  }
}

#tfsec:ignore:AVD-GIT-0004:The team has agreed that we don't need to sign commits
resource "github_branch_protection" "this" {
  #checkov:skip=CKV_GIT_5:The team has agreed that having 2 approvers will slow velocity

  repository_id = github_repository.this.id
  pattern       = var.branch_protection_pattern

  allows_deletions                = var.branch_protection_allows_deletions
  enforce_admins                  = var.branch_protection_enforce_admins
  force_push_bypassers            = var.branch_protection_force_push_bypassers
  push_restrictions               = var.branch_protection_push_restrictions
  require_signed_commits          = var.branch_protection_require_signed_commits
  required_linear_history         = var.branch_protection_required_linear_history
  require_conversation_resolution = var.branch_protection_require_conversation_resolution
  allows_force_pushes             = var.branch_protection_allows_force_pushes
  blocks_creations                = var.branch_protection_blocks_creations
  lock_branch                     = var.branch_protection_lock_branch

  required_pull_request_reviews {
    dismiss_stale_reviews           = var.branch_protection_required_pull_request_reviews_dismiss_stale_reviews
    restrict_dismissals             = var.branch_protection_required_pull_request_reviews_restrict_dismissals
    dismissal_restrictions          = var.branch_protection_required_pull_request_reviews_dismissal_restrictions
    pull_request_bypassers          = var.branch_protection_required_pull_request_reviews_pull_request_bypassers
    require_code_owner_reviews      = var.branch_protection_required_pull_request_reviews_require_code_owner_reviews
    require_last_push_approval      = var.branch_protection_required_pull_request_reviews_require_last_push_approval
    required_approving_review_count = var.branch_protection_required_pull_request_reviews_required_approving_review_count
  }

  required_status_checks {
    strict   = var.branch_protection_required_status_checks_strict
    contexts = var.branch_protection_required_status_checks_contexts
  }
}

resource "github_repository_dependabot_security_updates" "this" {
  repository = github_repository.this.id

  enabled = var.dependabot_security_updates_enabled
}

resource "github_team_repository" "admin" {
  for_each = var.access != null && var.access.admins != null ? { for team in var.access.admins : team => team } : {}

  team_id    = each.value
  repository = github_repository.this.name
  permission = "admin"
}

resource "github_team_repository" "maintainers" {
  for_each = var.access != null && var.access.maintainers != null ? { for team in var.access.maintainers : team => team } : {}

  team_id    = each.value
  repository = github_repository.this.name
  permission = "maintain"
}

resource "github_team_repository" "pushers" {
  for_each = var.access != null && var.access.pushers != null ? { for team in var.access.pushers : team => team } : {}

  team_id    = each.value
  repository = github_repository.this.name
  permission = "push"
}
