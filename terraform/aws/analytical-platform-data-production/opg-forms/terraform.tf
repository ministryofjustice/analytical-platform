terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-data-production/opg-forms/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.28.0"
    }
  }
  required_version = "~> 1.5"
}
provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}
