data "github_repositories" "analytical-platform-repositories" {
  query = "org:ministryofjustice archived:false analytics-platform-infrastructure"
  sort  = "stars"
}

data "aws_caller_identity" "current" {
  provider = aws.session-info
}

data "aws_iam_session_context" "whoami" {
  provider = aws.session-info
  arn      = data.aws_caller_identity.current.arn
}