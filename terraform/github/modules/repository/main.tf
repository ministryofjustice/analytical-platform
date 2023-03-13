locals {
  base_topics   = ["data-platform", "civil-service"]
  module_topics = ["terraform-module"]
  topics        = var.type == "core" ? local.base_topics : concat(local.base_topics, local.module_topics)
}

# Repository basics
resource "github_repository" "default" {
  #ts:skip=AC_GITHUB_0002 Disabling privateRepoEnabled check as we have a valid use case for public repos
  name                   = var.name
  description            = join(" • ", [var.description, "This repository is defined and managed in Terraform"])
  homepage_url           = var.homepage_url
  visibility             = var.visibility
  has_issues             = true
  has_projects           = true
  has_wiki               = var.type == "core" ? true : false
  has_downloads          = true
  is_template            = var.type == "template" ? true : false
  allow_merge_commit     = var.type == "app" ? true : false # Temp fix for app-migration setup
  allow_squash_merge     = true
  allow_rebase_merge     = true
  delete_branch_on_merge = true
  auto_init              = false
  archived               = false
  archive_on_destroy     = true
  vulnerability_alerts   = true
  topics                 = concat(local.topics, var.topics)

  template {
    owner      = "ministryofjustice"
    repository = var.template_repo
  }

  # The `pages.source` block doesn't support dynamic blocks in GitHub provider version 4.3.2,
  # so we ignore the changes so it doesn't try to revert repositories that have manually set
  # their pages configuration.
  lifecycle {
    ignore_changes = [template, pages]
  }
}

resource "github_branch_protection" "default" {
  count = var.type == "app" ? 0 : 1 # Temp fix for app-migration setup
  #checkov:skip=CKV_GIT_6:"Following discussions with other teams we will not be enforcing signed commits currently"
  repository_id  = github_repository.default.id
  pattern        = "main"
  enforce_admins = true
  #tfsec:ignore:github-branch_protections-require_signed_commits
  require_signed_commits = var.require_signed_commits

  required_status_checks {
    strict   = true
    contexts = var.required_checks
  }

  #checkov:skip=CKV_GIT_5:"moj branch protection guidelines do not require 2 reviews"
  required_pull_request_reviews {
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
    required_approving_review_count = 1
    require_last_push_approval      = true
  }
}

resource "github_repository_tag_protection" "default" {
  repository = github_repository.default.id
  pattern    = "*"
}

# Secrets
resource "github_actions_secret" "default" {
  #checkov:skip=CKV_GIT_4:Although secrets are provided in plaintext, they are encrypted at rest
  for_each        = var.secrets
  repository      = github_repository.default.id
  secret_name     = each.key
  plaintext_value = each.value
}

resource "github_repository_environment" "default" {
  for_each    = var.environments
  environment = each.value
  repository  = github_repository.default.name
  deployment_branch_policy {
    protected_branches     = each.value == "prod" ? true : false
    custom_branch_policies = each.value == "prod" ? false : true
  }
}
