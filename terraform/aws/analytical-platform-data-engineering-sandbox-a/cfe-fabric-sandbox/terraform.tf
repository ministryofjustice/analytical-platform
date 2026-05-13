terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-data-engineering-sandbox-a/cfe-fabric-sandbox/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.21.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-1"
  dynamic "assume_role" {
    for_each = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? [] : [1]
    content {
      role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-engineering-sandbox-a"]}:role/GlobalGitHubActionAdmin"
    }
  }

  default_tags {
    tags = {
      business-unit          = "Central Digital"
      application            = "Analytical Platform"
      component              = "CFE Fabric Sandbox"
      environment            = "sandbox"
      is-production          = "false"
      owner                  = "data-engineering:DataEngineering-gg@justice.gov.uk"
      infrastructure-support = "data-engineering:DataEngineering-gg@justice.gov.uk"
      source-code            = "https://github.com/ministryofjustice/analytical-platform/tree/cfe-fabric-sandbox/terraform/aws/analytical-platform-data-engineering-sandbox-a/cfe-fabric-sandbox"
      de-sandbox-nuke-keep   = "true"
    }
  }
}
