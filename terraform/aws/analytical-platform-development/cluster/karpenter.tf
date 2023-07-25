module "karpenter" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.5.3"

  cluster_name = local.eks_cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
}

