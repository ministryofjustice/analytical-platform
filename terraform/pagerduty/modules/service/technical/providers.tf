terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.63.0"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.13.0"
    }
  }
}
