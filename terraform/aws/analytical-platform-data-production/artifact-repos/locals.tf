locals {
  github_actions_runner = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/github-actions-infrastructure"

  data_account_arn        = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:root"
  development_account_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:root"
  production_account_arn  = "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:root"

  repositories = {
    "analytical-platform-scheduler" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "analytical-platform-poc" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "allspark-notebook-moj" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "datascience-notebook-moj" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "nginx-proxy-jupyter" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "nginx-proxy-airflow" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "rshiny" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "auth-proxy" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "nginx-proxy" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    },
    "github-actions-template" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn]
    }
    "controlpanel_eks" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    }
    "rshiny-s2i" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    }
    "tiller" = {
      "allowed_push_arns" = [local.github_actions_runner]
      "allowed_pull_arns" = [local.data_account_arn, local.development_account_arn, local.production_account_arn]
    }
  }
}
