terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-data-engineering-sandbox-a/redshift-aurora-test/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
    # Note: Backend uses default credentials. Ensure you are authenticated to
    # analytical-platform-management-production before running terraform init.
    # Use: aws sso login --profile <management-profile>
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

data "aws_iam_session_context" "session" {
  provider = aws.session
  arn      = data.aws_caller_identity.session.arn
}

data "aws_caller_identity" "session" {
  provider = aws.session
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = local.tags
  }
}
