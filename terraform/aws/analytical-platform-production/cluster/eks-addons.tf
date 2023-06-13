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

##################################################
# AWS EBS CSI Driver
##################################################

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name                = module.eks.cluster_id
  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = var.eks_addon_versions["ebs-csi-driver"]
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = module.iam_assumable_role_ebs_csi_driver.iam_role_arn
}
