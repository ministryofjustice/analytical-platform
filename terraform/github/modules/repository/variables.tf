variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "topics" {
  type    = list(string)
  default = []
}

variable "visibility" {
  type    = string
  default = "public"
}

variable "archived" {
  type    = bool
  default = false
}

variable "archive_on_destroy" {
  type    = bool
  default = true
}

variable "is_template" {
  type    = bool
  default = false
}

variable "use_template" {
  type    = bool
  default = true
}

variable "template_repository" {
  type    = string
  default = "template-repository"
}

variable "has_discussions" {
  type    = bool
  default = false
}

variable "has_downloads" {
  type    = bool
  default = false
}

variable "has_issues" {
  type    = bool
  default = true
}

variable "has_projects" {
  type    = bool
  default = false
}

variable "has_wiki" {
  type    = bool
  default = false
}

variable "homepage_url" {
  type    = string
  default = "https://data-platform.service.justice.gov.uk"
}

variable "vulnerability_alerts" {
  type    = bool
  default = true
}

variable "auto_init" {
  type    = bool
  default = true
}

variable "allow_merge_commit" {
  type    = bool
  default = false
}

variable "merge_commit_title" {
  type    = string
  default = "MERGE_MESSAGE"
}

variable "merge_commit_message" {
  type    = string
  default = "PR_TITLE"
}

variable "allow_squash_merge" {
  type    = bool
  default = true
}

variable "squash_merge_commit_title" {
  type    = string
  default = "PR_TITLE"
}

variable "squash_merge_commit_message" {
  type    = string
  default = "COMMIT_MESSAGES"
}

variable "allow_update_branch" {
  type    = bool
  default = true
}

variable "allow_auto_merge" {
  type    = bool
  default = false
}

variable "allow_rebase_merge" {
  type    = bool
  default = true
}

variable "delete_branch_on_merge" {
  type    = bool
  default = true
}

variable "pages_enabled" {
  type    = bool
  default = false
}

variable "pages_configuration" {
  type = object({
    cname = string
    source = object({
      branch = string
      path   = string
    })
  })
  default = null
}

variable "advanced_security_status" {
  type    = string
  default = "enabled"
}

variable "secret_scanning_status" {
  type    = string
  default = "enabled"
}

variable "secret_scanning_push_protection_status" {
  type    = string
  default = "enabled"
}

variable "branch_protection_pattern" {
  type    = string
  default = "main"
}

variable "branch_protection_allows_deletions" {
  type    = bool
  default = false
}

variable "branch_protection_enforce_admins" {
  type    = bool
  default = true
}

variable "branch_protection_force_push_bypassers" {
  type    = list(string)
  default = []
}

variable "branch_protection_push_restrictions" {
  type    = list(string)
  default = []
}

variable "branch_protection_require_signed_commits" {
  type    = bool
  default = false
}

variable "branch_protection_required_linear_history" {
  type    = bool
  default = false
}

variable "branch_protection_require_conversation_resolution" {
  type    = bool
  default = true
}

variable "branch_protection_allows_force_pushes" {
  type    = bool
  default = false
}

variable "branch_protection_blocks_creations" {
  type    = bool
  default = false
}

variable "branch_protection_lock_branch" {
  type    = bool
  default = false
}

variable "branch_protection_required_pull_request_reviews_dismiss_stale_reviews" {
  type    = bool
  default = true
}

variable "branch_protection_required_pull_request_reviews_restrict_dismissals" {
  type    = bool
  default = false
}

variable "branch_protection_required_pull_request_reviews_dismissal_restrictions" {
  type    = list(string)
  default = []
}

variable "branch_protection_required_pull_request_reviews_pull_request_bypassers" {
  type    = list(string)
  default = []
}

variable "branch_protection_required_pull_request_reviews_require_code_owner_reviews" {
  type    = bool
  default = true
}

variable "branch_protection_required_pull_request_reviews_require_last_push_approval" {
  type    = bool
  default = true
}

variable "branch_protection_required_pull_request_reviews_required_approving_review_count" {
  type    = number
  default = 1
}

variable "branch_protection_required_status_checks_strict" {
  type    = bool
  default = true
}

variable "branch_protection_required_status_checks_contexts" {
  type    = list(string)
  default = []
}

variable "dependabot_security_updates_enabled" {
  type    = bool
  default = true
}

variable "access" {
  type = object({
    admins      = optional(list(string))
    maintainers = optional(list(string))
    pushers     = optional(list(string))
  })
  default = {
    admins      = []
    maintainers = []
    pushers     = []
  }
}
