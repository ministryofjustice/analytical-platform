terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
      configuration_aliases = [aws.platform_engineer_admin_source]
    }
  }
  required_version = "~> 1.10"
}
