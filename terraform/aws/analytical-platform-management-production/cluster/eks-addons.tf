##################################################
# VPC CNI
##################################################

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "vpc-cni"
  addon_version               = var.eks_addon_versions["vpc-cni"]
  resolve_conflicts_on_update = "OVERWRITE"
}

##################################################
# CoreDNS
##################################################

resource "aws_eks_addon" "coredns" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "coredns"
  addon_version               = var.eks_addon_versions["coredns"]
  resolve_conflicts_on_update = "OVERWRITE"
}

##################################################
# Kube Proxy
##################################################

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "kube-proxy"
  addon_version               = var.eks_addon_versions["kube-proxy"]
  resolve_conflicts_on_update = "OVERWRITE"
}
