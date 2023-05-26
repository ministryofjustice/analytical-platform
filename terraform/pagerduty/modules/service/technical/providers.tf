terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.0.1"
    }
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.14.5"
    }
  }
}
