terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
      configuration_aliases = [
        aws.source,
        aws.destination
      ]
    }
  }
}
