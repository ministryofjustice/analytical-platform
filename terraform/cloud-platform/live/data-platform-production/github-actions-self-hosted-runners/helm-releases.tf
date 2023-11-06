##################################################
# moj-analytical-services/create-a-derived-table
##################################################

data "aws_secretsmanager_secret" "github_actions_self_hosted_runner_create_a_derived_table" {
  provider = aws.analytical-platform-management-production

  name = "github/actions/self-hosted-runner/create-a-derived-table"
}

data "aws_secretsmanager_secret_version" "github_actions_self_hosted_runner_create_a_derived_table" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.github_actions_self_hosted_runner_create_a_derived_table.id
}

resource "helm_release" "github_actions_self_hosted_runners_create_a_derived_table" {
  name      = "gha-shr-create-a-derived-table"
  chart     = "./src/helm/charts/github-actions-self-hosted-runners"
  namespace = "data-platform-production"

  set {
    name  = "github.organisation"
    value = "moj-analytical-services"
  }

  set {
    name  = "github.repository"
    value = "create-a-derived-table"
  }

  set {
    name  = "github.token"
    value = data.aws_secretsmanager_secret_version.github_actions_self_hosted_runner_create_a_derived_table.secret_string
  }

  set {
    name  = "irsa.roleArn"
    value = "arn:aws:iam::593291632749:role/create-a-derived-table"
  }

  set {
    name  = "runner.labels"
    value = "moj-cloud-platform"
  }
}
