terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "global/baseline/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.0"
    }
  }
  required_version = "~> 1.5"
}

##################################################
# Session
##################################################

provider "aws" {
  alias = "session"
}

##################################################
# Data Development
##################################################

provider "aws" {
  alias  = "analytical-platform-data-development-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-data-development-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Engineering Production
##################################################

provider "aws" {
  alias  = "analytical-platform-data-engineering-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-data-engineering-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Engineering Sandbox A
##################################################

provider "aws" {
  alias  = "analytical-platform-data-engineering-sandbox-a-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-data-engineering-sandbox-a-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Production
##################################################

provider "aws" {
  alias  = "analytical-platform-data-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-data-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Development
##################################################

provider "aws" {
  alias  = "analytical-platform-development-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-development-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Landing Production
##################################################

provider "aws" {
  alias  = "analytical-platform-landing-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-landing-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-landing-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-landing-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Management Production
##################################################

provider "aws" {
  alias  = "analytical-platform-management-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-management-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Production
##################################################

provider "aws" {
  alias  = "analytical-platform-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}
