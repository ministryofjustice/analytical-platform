terraform {
  backend "s3" {
    acl            = "private"
    bucket         = "global-tf-state-aqsvzyd5u9"
    encrypt        = true
    key            = "terraform/dpat-eks/production/github-actions/create-a-derived-table/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "global-tf-state-aqsvzyd5u9-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.26.0"
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

provider "kubernetes" {
  host                   = data.aws_secretsmanager_secret.dpat_eks_production_cluster_endpoint.secret_string
  cluster_ca_certificate = base64decode(data.aws_secretsmanager_secret.dpat_eks_production_cluster_ca_cert.secret_string)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../../../../../scripts/eks/terraform-authentication.sh", data.aws_secretsmanager_secret.dpat_eks_production_account.secret_string, data.aws_secretsmanager_secret.dpat_eks_production_cluster_name.secret_string]
  }
}
