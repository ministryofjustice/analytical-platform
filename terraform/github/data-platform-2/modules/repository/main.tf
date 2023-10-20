#tfsec:ignore:AVD-GIT-0001:Ministry of Justice follow GOV.UK Service Manual guidance on coding in the open (https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable)
#ts:skip=accurics.github.IAM.1 Ministry of Justice follow GOV.UK Service Manual guidance on coding in the open (https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable)
resource "github_repository" "this" {
  #checkov:skip=CKV_GIT_1:Ministry of Justice follow GOV.UK Service Manual guidance on coding in the open (https://www.gov.uk/service-manual/technology/making-source-code-open-and-reusable)

  name        = var.name
  description = join(" • ", [var.description, "This repository is defined and managed in Terraform"])
  topics      = var.topics
  visibility  = var.visibility

  has_discussions      = var.has_discussions
  has_downloads        = var.has_downloads
  has_issues           = var.has_issues
  has_projects         = var.has_projects
  has_wiki             = var.has_wiki
  homepage_url         = var.homepage_url
  vulnerability_alerts = var.vulnerability_alerts

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
