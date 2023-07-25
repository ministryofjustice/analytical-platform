module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter?ref=6217d0eaab4c864ec4d40a31538e78a7fbcee5e3" # version 19.15.3

  cluster_name = local.eks_cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}