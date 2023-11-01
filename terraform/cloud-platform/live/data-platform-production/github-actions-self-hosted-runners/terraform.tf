terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "cloud-platform/live/data-platform-production/github-actions-self-hosted-runners/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.23.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.11.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  alias  = "analytical-platform-management-production"
  region = "eu-west-2"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.aws_secretsmanager_secret_version.cloud_platform_live_cluster_endpoint.secret_string}"
    cluster_ca_certificate = base64decode(data.aws_secretsmanager_secret_version.cloud_platform_live_cluster_ca_cert.secret_string)
    token                  = data.aws_secretsmanager_secret_version.cloud_platform_live_data_platform_production_token.secret_string
  }
}
