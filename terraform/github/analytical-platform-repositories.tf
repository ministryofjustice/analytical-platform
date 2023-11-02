locals {
  analytical_platform_repositories = {
    "analytics-platform-infrastructure" = {
      name                                   = "analytics-platform-infrastructure"
      description                            = "Analytical Platform Infrastructure"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      archived                               = true
      use_template                           = false
      vulnerability_alerts                   = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "analytics-platform-helm-charts" = {
      name                                   = "analytics-platform-helm-charts"
      description                            = "Analytical Platform Helm Charts"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      has_issues                             = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "analytics-platform-rshiny" = {
      name         = "analytics-platform-rshiny"
      description  = "Analytical Platform RShiny Container"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      has_issues   = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "analytics-platform-control-panel" = {
      name                                   = "analytics-platform-control-panel"
      description                            = "Analytical Platform Control Panel"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      homepage_url                           = "https://controlpanel.services.analytical-platform.service.justice.gov.uk"
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    "analytics-platform-control-panel-public" = {
      name         = "analytics-platform-control-panel-public"
      description  = "Analytical Platform Control Panel Public"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytical-platform-migration-scripts" = {
      name                                   = "analytical-platform-migration-scripts"
      description                            = "Analytical Platform Migration Scripts"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-ops" = {
      name                                   = "analytics-platform-ops"
      description                            = "Analytical Platform Ops"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      archived                               = true
      use_template                           = false
      vulnerability_alerts                   = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-auth-proxy" = {
      name                                   = "analytics-platform-auth-proxy"
      description                            = "Analytical Platform Auth Proxy"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-shiny-server" = {
      name         = "analytics-platform-shiny-server"
      description  = "Analytical Platform Shiny Server"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytical-platform-iam" = {
      name                                   = "analytical-platform-iam"
      description                            = "Analytical Platform IAM"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      archived                               = true
      use_template                           = false
      visibility                             = "internal"
      vulnerability_alerts                   = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-aws-federated-login" = {
      name                                   = "analytics-platform-aws-federated-login"
      description                            = "Analytical Platform AWS Federated Login"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      branch_protection_pattern              = "master"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-rstudio" = {
      name                                   = "analytics-platform-rstudio"
      description                            = "Analytical Platform RStudio"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-rstudio-public" = {
      name         = "analytics-platform-rstudio-public"
      description  = "Analytical Platform RStudio Public"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytical-platform-nginx-proxy" = {
      name                                   = "analytical-platform-nginx-proxy"
      description                            = "Analytical Platform NGINX Proxy"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      use_template                           = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-config" = {
      name         = "analytics-platform-config"
      description  = "Analytical Platform Config"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-auth0" = {
      name                      = "analytics-platform-auth0"
      description               = "Analytical Platform Auth0"
      topics                    = ["ministryofjustice", "analytical-platform"]
      use_template              = false
      branch_protection_pattern = "master"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytics-platform-jupyter-notebook" = {
      name                                   = "analytics-platform-jupyter-notebook"
      description                            = "Analytical Platform Jupyter Notebook"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      use_template                           = false
      visibility                             = "internal"
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "analytical-platform-nginx-jupyter" = {
      name                                   = "analytical-platform-nginx-jupyter"
      description                            = "Analytical Platform NGINX Jupyter"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      use_template                           = false
      visibility                             = "internal"
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-module-template" = {
      name                                   = "ap-terraform-module-template"
      description                            = "Analytical Platform Terraform Module Template"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      is_template                            = true
      use_template                           = false
      archived                               = true
      vulnerability_alerts                   = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-test-github-workflow" = {
      name                                   = "ap-test-github-workflow"
      description                            = "Analytical Platform Test Github Workflow"
      topics                                 = ["ministryofjustice", "analytical-platform"]
      visibility                             = "internal"
      archived                               = true
      use_template                           = false
      vulnerability_alerts                   = false
      advanced_security_status               = "disabled"
      secret_scanning_status                 = "disabled"
      secret_scanning_push_protection_status = "disabled"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-eks-core" = {
      name                = "ap-terraform-eks-core"
      description         = "Analytical Platform Terraform EKS Core"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-vpc-endpoints" = {
      name                = "ap-terraform-vpc-endpoints"
      description         = "Analytical Platform Terraform VPC Endpoints"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-eks-dns" = {
      name                = "ap-terraform-eks-dns"
      description         = "Analytical Platform Terraform EKS DNS"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-iam-roles" = {
      name         = "ap-terraform-iam-roles"
      description  = "Analytical Platform Terraform IAM Roles"
      topics       = ["ministryofjustice", "analytical-platform"]
      use_template = false
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-control-panel-iam" = {
      name                = "ap-terraform-control-panel-iam"
      description         = "Analytical Platform Terraform Control Panel IAM"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-app-cicd-resources" = {
      name                = "ap-terraform-app-cicd-resources"
      description         = "Analytical Platform Terraform App CICD Resources"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-app-deployment-role" = {
      name                = "ap-terraform-app-deployment-role"
      description         = "Analytical Platform Terraform App Deployment Role"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-app-github-repo" = {
      name                = "ap-terraform-app-github-repo"
      description         = "Analytical Platform Terraform App Github Repo"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-ecr-repository" = {
      name                = "ap-terraform-ecr-repository"
      description         = "Analytical Platform Terraform ECR Repository"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-github-id-provider-config" = {
      name                = "ap-terraform-github-id-provider-config"
      description         = "Analytical Platform Terraform Github ID Provider Config"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    },
    "ap-terraform-aws-oidc-provider" = {
      name                = "ap-terraform-aws-oidc-provider"
      description         = "Analytical Platform Terraform AWS OIDC Provider"
      topics              = ["ministryofjustice", "analytical-platform"]
      use_template        = true
      template_repository = "ap-terraform-module-template"
      access = {
        admins  = [module.data_platform_teams["data-platform-apps-and-tools"].id]
        pushers = [module.data_platform_team.id]
      }
    }
    /*
      Analytical Platform Repositories that could be managed in code:
        - analytical-platform-data-engineering
    */
    /*
      Analytical Platform Repositories that are already archived:
        - analytics-platform-restarter
        - analytical-platform-tools-operator
        - analytics-platform-airflow-docker-image
        - analytical-platform-support-rota
        - analytics-platform-idler
        - ap-terraform-bootstrap
        - fab-oidc
        - analytics-platform-go-unidler
        - analytics-platform-data-engineering-ops
        - analytics-platform-websocket-status
        - analytics-platform-concourse-webhook-dispatcher
        - analytics-platform-data-infrastructure
        - ap-terraform-efs-burst-credit-alarm
        - ap-terraform-private-link
        - ap-terraform-aws-rds-alarm
        - scaler
        - platform-application-operator
        - ap-diagrams
        - analytical-platform-jupyterhub
        - analytics-platform
        - analytics-platform-concourse-helm-charts
        - analytics-platform-concourse-pipelines
        - analytics-platform-cran-proxy
        - analytics-platform-rstudio-auth-proxy
        - analytics-platform-common-concourse-tasks
        - analytics-platform-concourse-github-org-resource
        - analytical-platform-aws-security
        - analytical-platform-public-keys
        - analytics-platform-auth-proxy-public
        - analytics-platform-training-resources
        - analytics-platform-flux
        - analytical-platform-org
        - analytics-platform-custodian
        - analytics-platform-concourse-auth0-client-resource
        - analytics-platform-concourse-workers-cleaner
        - analytical-platform-pipeline
        - analytical-platform-auth0-user-exports
        - analytics-platform-status-page
        - analytics-platform-buckets-archiver
        - analytics-platform-concourse-ecr-repo-resource
        - analytics-platform-fluentd
        - analytics-platform-airflow-example-dags
        - analytical-platform-infrastructure-pulumi
        - analytical-platform-nfs
        - analytics-platform-kibana-auth-proxy
        - python-fly
        - analytics-platform-control-panel-frontend
        - analytics-platform-unidler
        - analytical-platform-tf-module-nfs
        - analytics-platform-atlantis-example
        - analytics-platform-atlantis-docker
        - kaniko-resource
        - concourse-helm-resource
        - Analyticsplatform
        - analytics-platform-control-panel-prototype
        - analytics-qnd-r-example
    */
  }
}

module "analytical_platform_repositories" {
  source = "./modules/repository"

  for_each = { for repository in local.analytical_platform_repositories : repository.name => repository }

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

  branch_protection_pattern                                                       = lookup(each.value, "branch_protection_pattern", "main")
  branch_protection_allows_deletions                                              = lookup(each.value, "branch_protection_allows_deletions", false)
  branch_protection_enforce_admins                                                = lookup(each.value, "branch_protection_enforce_admins", true)
  branch_protection_force_push_bypassers                                          = lookup(each.value, "branch_protection_force_push_bypassers", [])
  branch_protection_push_restrictions                                             = lookup(each.value, "branch_protection_push_restrictions", [])
  branch_protection_require_signed_commits                                        = lookup(each.value, "branch_protection_require_signed_commits", false)
  branch_protection_required_linear_history                                       = lookup(each.value, "branch_protection_required_linear_history", false)
  branch_protection_require_conversation_resolution                               = lookup(each.value, "branch_protection_require_conversation_resolution", true)
  branch_protection_allows_force_pushes                                           = lookup(each.value, "branch_protection_allows_force_pushes", false)
  branch_protection_blocks_creations                                              = lookup(each.value, "branch_protection_blocks_creations", false)
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
