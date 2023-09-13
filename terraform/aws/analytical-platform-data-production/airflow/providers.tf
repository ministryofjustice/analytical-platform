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

# provider "kubernetes" {
#   host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
#   cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.cluster.token
# }

provider "kubernetes" {
  alias                  = "dev-airflow-cluster"
  host                   = aws_eks_cluster.airflow_dev_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.airflow_dev_eks_cluster.name]
    command     = "aws"
  }
}

# provider "helm" {
#   alias = "dev-airflow-cluster"
#   kubernetes {
#     host                   = aws_eks_cluster.airflow_dev_eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.airflow_dev_eks_cluster.name]
#       command     = "aws"
#     }
#   }
# }

provider "kubernetes" {
  alias                  = "prod-airflow-cluster"
  host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
  #   exec {
  #     api_version = "client.authentication.k8s.io/v1beta1"
  #     args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.airflow_prod_eks_cluster.name]
  #     command     = "aws"
  #   }
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "bash"
    args        = ["../../../../scripts/eks/terraform-authentication.sh", data.aws_caller_identity.current.account_id, aws_eks_cluster.airflow_prod_eks_cluster.name]
  }
}


# exec {
#   api_version = "client.authentication.k8s.io/v1beta1"
#   command     = "bash"
#   args        = ["../../../../scripts/eks/terraform-authentication.sh", data.aws_caller_identity.current.account_id, module.eks.cluster_name]
# }

# provider "helm" {
#   alias = "prod-airflow-cluster"
#   kubernetes {
#     host                   = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
#     cluster_ca_certificate = base64decode(aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data)
#     exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.airflow_prod_eks_cluster.name]
#       command     = "aws"
#     }
#   }
# }
