data "aws_caller_identity" "current" {
  provider = aws.session-info
}

data "aws_iam_session_context" "whoami" {
  provider = aws.session-info
  arn      = data.aws_caller_identity.current.arn
}

data "aws_secretsmanager_secret" "github_token" {
  provider = aws.management
  name     = "github-token"
}

data "aws_secretsmanager_secret_version" "github_token" {
  provider  = aws.management
  secret_id = data.aws_secretsmanager_secret.github_token.id
}

data "github_repositories" "app_repositories" {
  provider = github
  query    = "org:ministryofjustice topic:aws topic:data-platform-apps topic:data-platform-apps-and-tools topic:helm topic:cloud-platform"
}
