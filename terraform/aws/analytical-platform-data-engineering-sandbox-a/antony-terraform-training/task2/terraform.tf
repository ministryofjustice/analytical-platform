provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-data-engineering-sandbox-a/antony-terraform-training/task2/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.27.0"
    }
  }
  required_version = "~> 1.5"
}
