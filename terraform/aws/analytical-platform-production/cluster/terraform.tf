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
      version = "0.45.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.65.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.20.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }
  required_version = "~> 1.2"
}

provider "auth0" {
  domain        = local.auth0_credentials.auth0_domain
  client_id     = local.auth0_credentials.client_id
  client_secret = local.auth0_credentials.client_secret
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids[var.target_account]}:role/${var.assume_role}"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "data-production"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["data-production"]}:role/${var.assume_role}"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "management-production"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["management-production"]}:role/${var.assume_role}"
  }
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
