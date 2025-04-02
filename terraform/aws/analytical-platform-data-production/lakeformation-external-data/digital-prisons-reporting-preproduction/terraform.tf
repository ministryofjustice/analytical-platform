terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-data-production/lakeformation-external-data/digital-prisons-reporting-preproduction/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.93.0"
    }
  }

  required_version = "~> 1.5"
}

provider "aws" {
  alias  = "session"
  region = "eu-west-2"
}

provider "aws" {
  alias  = "digital_prisons_reporting_preprod_eu_west_2"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["digital-prisons-reporting-preproduction"]}:role/analytical-platform-data-production-share-role"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${local.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}


provider "aws" {
  alias  = "analytical_platform_management_production"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${local.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}
