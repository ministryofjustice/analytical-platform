terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "0.11.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
    }
  }
}

provider "coder" {}

provider "kubernetes" {}
