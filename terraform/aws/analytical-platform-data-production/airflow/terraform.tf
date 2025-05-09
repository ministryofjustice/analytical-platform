terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "aws/analytical-platform-data-production/airflow/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.94.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
  required_version = "~> 1.5"
}

provider "aws" {
  alias = "session"
}

provider "aws" {
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/GlobalGitHubActionAdmin"
  }
  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias  = "analytical-platform-development"
  region = "eu-west-1"
  assume_role {
    role_arn = "arn:aws:iam::${var.account_ids["analytical-platform-development"]}:role/GlobalGitHubActionAdmin"
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

provider "kubernetes" {
  alias                  = "prod-airflow-cluster"
  host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.airflow_prod_eks_cluster.name,
      "--role-arn",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/restricted-admin"
    ]
    command = "aws"
  }
}

provider "helm" {
  alias = "prod-airflow-cluster"
  kubernetes {
    host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        aws_eks_cluster.airflow_prod_eks_cluster.name,
        "--role-arn",
        "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/restricted-admin"
      ]
      command = "aws"
    }
  }
}

provider "kubectl" {
  alias = "prod-airflow-cluster"

  host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      aws_eks_cluster.airflow_prod_eks_cluster.name,
      "--role-arn",
      "arn:aws:iam::${var.account_ids["analytical-platform-data-production"]}:role/restricted-admin"
    ]
    command = "aws"
  }
}
