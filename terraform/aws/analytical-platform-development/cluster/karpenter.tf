module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter?ref=v19.15.3"

  cluster_name = local.eks_cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}