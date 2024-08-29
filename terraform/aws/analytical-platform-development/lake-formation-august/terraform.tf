terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-development/lake-formation-august/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.52.0"
    }
  }
  required_version = "~> 1.5"
}

### SOURCE ACCOUNT

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

### TARGET ACCOUNT

provider "aws" {
  alias  = "analytical-platform-compute-development-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-compute-development"]}:role/lake-formation-share20240807082011856100000001"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias = "session"
}
