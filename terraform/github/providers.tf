provider "github" {
  owner = "ministryofjustice"
  token = var.team_github_token
}

provider "github" {
  alias = "repository-github"
  owner = "ministryofjustice"
  token = var.repository_github_token
}

provider "aws" {
  region = "eu-west-2"
}
