terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-development/next-gen-network/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.25.0"
    }
  }
  required_version = "~> 1.10"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}
