locals {
  eks_cluster_name = "github-actions-moj-${random_string.suffix.result}"
  vpc_name         = "github-actions-moj-vpc"
}
