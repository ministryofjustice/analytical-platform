terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = {
      version = "4.64.0"
      source  = "hashicorp/aws"
    }
    github = {
      version = "5.23.0"
      source  = "integrations/github"
    }
    time = {
      version = "0.9.1"
      source  = "hashicorp/time"
    }
    http = {
      version = "3.2.1"
      source  = "hashicorp/http"
    }
    null = {
      version = "3.2.1"
      source  = "hashicorp/null"
    }
  }
}
