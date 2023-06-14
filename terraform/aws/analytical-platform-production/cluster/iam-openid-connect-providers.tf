##################################################
# Cloud Platform (Data Production)
##################################################

resource "aws_iam_openid_connect_provider" "cloud_platform" {
  provider = aws.analytical-platform-data-production

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.cloud_platform_eks_oidc_thumbprint]
  url             = local.cloud_platform_eks_oidc_url
}

##################################################
# Tools EKS (Data Production)
##################################################

resource "aws_iam_openid_connect_provider" "cross_account_irsa" {
  provider = aws.analytical-platform-data-production

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cross_account_irsa_oidc_issuer.certificates[0].sha1_fingerprint]
  url             = module.eks.cluster_oidc_issuer_url
}
