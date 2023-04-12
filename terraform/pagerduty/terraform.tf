terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "data-platform/pagerduty/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.62.0"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.12.2"
    }
  }
}

provider "aws" {}

provider "aws" {
  alias  = "management"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.current.issuer_arn)) ? null : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/GlobalGitHubActionAdmin"
  }
}

provider "pagerduty" {
  token = data.aws_secretsmanager_secret_version.pagerduty_token.secret_string
}
