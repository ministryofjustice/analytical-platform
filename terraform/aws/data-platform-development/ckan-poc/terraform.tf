terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.65.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      business-unit          = "Platforms"
      application            = "Data Platform"
      component              = "Data Catalogue"
      environment            = "development"
      is-production          = "false"
      owner                  = "data-platform:data-platform-tech@digital.justice.gov.uk"
      infrastructure-support = "data-platform:data-platform-tech@digital.justice.gov.uk"
      source-code            = "github.com/ministryofjustice/data-platform"
    }
  }
}
