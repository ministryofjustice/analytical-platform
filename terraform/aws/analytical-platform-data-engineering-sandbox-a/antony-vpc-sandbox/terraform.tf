terraform {

  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
    encrypt        = true
    key            = "aws/analytical-platform-data-engineering-sandbox-a/antony-vpc-sandbox/terraform.tfstate"
    region         = "eu-west-2"
  }

  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}
