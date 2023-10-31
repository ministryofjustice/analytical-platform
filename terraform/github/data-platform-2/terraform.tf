terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "github/data-platform-2/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
    github = {
      source  = "integrations/github"
      version = "5.41.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "github" {
  owner = "ministryofjustice"
  token = data.aws_secretsmanager_secret_version.github_token.secret_string
}


provider "github" {
  alias = "moj-analytical-services"
  owner = "moj-analytical-services"
  token = data.aws_secretsmanager_secret_version.github_token.secret_string
}
