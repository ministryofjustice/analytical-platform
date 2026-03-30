terraform {
  # backend "s3" {
  #   acl     = "private"
  #   bucket  = "global-tf-state-aqsvzyd5u9"
  #   encrypt = true
  #   key     = "aws/analytical-platform-data-engineering-sandbox-a/moj-de-user-guidance-tool/terraform.tfstate"
  #   region  = "eu-west-2"
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
  }

  default_tags {
    tags = {
      business-unit          = "Central Digital"
      application            = "Analytical Platform"
      component              = "MOJ DE User Guidance"
      environment            = "sandbox"
      is-production          = "false"
      owner                  = "analytical-platform:analytical-platform@digital.justice.gov.uk"
      infrastructure-support = "analytical-platform:analytical-platform@digital.justice.gov.uk"
      source-code            = "github.com/ministryofjustice/analytical-platform"
    }
  }
}
