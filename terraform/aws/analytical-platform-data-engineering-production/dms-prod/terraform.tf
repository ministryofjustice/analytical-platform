terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-data-engineering-production/dms-prod/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.88.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

# Comment out to run terraform plan locally
provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

# N.B. this provider isn't being used currently
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
