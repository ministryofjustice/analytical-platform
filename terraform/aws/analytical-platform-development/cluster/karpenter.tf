module "karpenter" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "19.15.3"

  cluster_name = local.eks_cluster_name

  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]
}

resource "aws_security_group" "karpenter" {
  description = "Provides karpenter with a map of subnets to deploy nodes"
  vpc_id      = module.vpc.vpc_id

  tags = {
    "karpenter.sh/discovery" = local.eks_cluster_name
  }
}

resource "aws_security_group_rule" "karpenter" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.karpenter.id
  security_group_id        = aws_security_group.karpenter.id  
}

resource "aws_security_group_rule" "eks_node_karpenter" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.eks.worker_security_group_id
  security_group_id        = aws_security_group.karpenter.id  
}
