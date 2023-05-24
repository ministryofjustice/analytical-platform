terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.14.5"
    }
  }
}
