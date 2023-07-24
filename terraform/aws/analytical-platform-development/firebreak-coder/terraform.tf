terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-development/firebreak-coder/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.9.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.10.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.22.0"
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
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-data-production"
  region = "eu-west-2"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
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
    host                   = data.aws_eks_cluster.open_metadata.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.open_metadata.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "bash"
      args        = ["../../../../scripts/eks/terraform-authentication.sh", data.aws_caller_identity.current.account_id, data.aws_eks_cluster.open_metadata.id]
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.open_metadata.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.open_metadata.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../../../../scripts/eks/terraform-authentication.sh", data.aws_caller_identity.current.account_id, data.aws_eks_cluster.open_metadata.id]
  }
}
