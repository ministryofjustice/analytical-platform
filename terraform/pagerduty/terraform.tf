terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "data-platform/pagerduty/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.60.0"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.11.2"
    }
  }
}

provider "aws" {
  alias  = "management"
  region = "eu-west-1"
}

provider "pagerduty" {
  token = data.aws_secretsmanager_secret_version.pagerduty_token.secret_string
}
