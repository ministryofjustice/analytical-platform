data "aws_secretsmanager_secret" "github_actions_self_hosted_runner_create_a_derived_table" {
  provider = aws.analytical-platform-management-production

  name = "github/actions/self-hosted-runner/create-a-derived-table"
}

data "aws_secretsmanager_secret_version" "github_actions_self_hosted_runner_create_a_derived_table" {
  provider = aws.analytical-platform-management-production

  secret_id = data.aws_secretsmanager_secret.github_actions_self_hosted_runner_create_a_derived_table.id
}

resource "helm_release" "create_a_derived_table" {
  name       = "actions-runner-mojas-create-a-derived-table"
  repository = "oci://ghcr.io/ministryofjustice/data-platform-charts"
  version    = "1.0.0"
  chart      = "actions-runner"
  namespace  = "actions-runners"

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
    value = "moj-data-platform"
  }
}
