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
      version = "5.3.0"
    }
  }
  required_version = ">= 1.2.2"
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
  alias  = "data-development-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "data-development-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Engineering Production
##################################################

provider "aws" {
  alias  = "data-engineering-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "data-engineering-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-engineering-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Engineering Sandbox A
##################################################

provider "aws" {
  alias  = "data-engineering-sandbox-a-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "data-engineering-sandbox-a-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Data Production
##################################################

provider "aws" {
  alias  = "data-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "data-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Development
##################################################

provider "aws" {
  alias  = "development-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "development-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Landing Production
##################################################

provider "aws" {
  alias  = "landing-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["landing-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "landing-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["landing-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Management Production
##################################################

provider "aws" {
  alias  = "management-production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "management-production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

##################################################
# Production
##################################################

provider "aws" {
  alias  = "production-eu-west-1"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "production-eu-west-2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}
