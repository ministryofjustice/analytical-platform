terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "auth0/ministryofjustice-data-platform-development/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.20.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "1.27.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  alias  = "analytical-platform-management-production"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "auth0" {
  domain        = data.aws_secretsmanager_secret_version.auth0_domain.secret_string
  client_id     = data.aws_secretsmanager_secret_version.auth0_client_id.secret_string
  client_secret = data.aws_secretsmanager_secret_version.auth0_client_secret.secret_string
}
