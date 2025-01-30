terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.management, aws.target]
    }
  }
  required_version = "~> 1.10"
}
