data "github_repositories" "analytical-platform-repositories" {
  query = "org:ministryofjustice archived:false analytics-platform-infrastructure"
  sort  = "stars"
}

data "aws_caller_identity" "current" {}