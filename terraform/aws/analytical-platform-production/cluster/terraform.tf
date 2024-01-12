terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "ap/prod/cluster/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    auth0 = {
      source  = "auth0/auth0"
      version = "1.1.2"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.32.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.25.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
  required_version = "~> 1.5"
}

provider "auth0" {
  domain        = local.auth0_credentials.auth0_domain
  client_id     = local.auth0_credentials.client_id
  client_secret = local.auth0_credentials.client_secret
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  alias  = "analytical-platform-data-production"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-management-production"
  region = "eu-west-1"
  assume_role {
    role_arn = can(regex("AdministratorAccess", data.aws_iam_session_context.session.issuer_arn)) ? null : "arn:aws:iam::${var.account_ids["analytical-platform-management-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "control-panel-sqs-region"
  region = "eu-west-1"
  default_tags {
    tags = var.tags
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "random" {}
