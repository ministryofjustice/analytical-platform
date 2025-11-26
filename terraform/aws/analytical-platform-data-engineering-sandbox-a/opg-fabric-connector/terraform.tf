terraform {
  backend "s3" {
    acl          = "private"
    bucket       = "global-tf-state-aqsvzyd5u9"
    encrypt      = true
    key          = "aws/analytical-platform-data-engineering-sandbox-a/opg-fabric-connector/terraform.tfstate"
    region       = "eu-west-2"
    use_lockfile = true
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.11.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      business-unit          = "Central Digital"
      application            = "Analytical Platform"
      component              = "OPG Fabric Connector"
      environment            = "sandbox"
      is-production          = "false"
      owner                  = "data-engineering:DataEngineering-gg@justice.gov.uk"
      infrastructure-support = "data-engineering:DataEngineering-gg@justice.gov.uk"
      source-code            = "https://github.com/ministryofjustice/analytical-platform/tree/opg-fabric-connector/terraform/aws/analytical-platform-data-engineering-sandbox-a/opg-fabric-connector"
      de-sandbox-nuke-keep   = "true"
    }
  }
}
