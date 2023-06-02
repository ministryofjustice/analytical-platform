terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.1.0"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.15.0"
    }
  }
}
