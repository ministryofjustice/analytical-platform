terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.8.0"
    }
  }

  backend "s3" {
    acl     = "private"
    bucket  = "probation-terraform-state-sandbox-test"
    encrypt = true
    key     = "rds-export-serj-test/terraform.tfstate"
    #use_lockfile = true
    region = "eu-west-1"
    profile = "sso-de-sandbox"
  }
}
