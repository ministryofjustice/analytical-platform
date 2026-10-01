terraform {
  required_version = ">= 1.5.0"

  required_providers {
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = ">= 3.33.1"
    }
  }
}
