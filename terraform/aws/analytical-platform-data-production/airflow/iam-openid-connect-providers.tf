resource "aws_iam_openid_connect_provider" "analytical_platform_development" {
  url             = data.aws_eks_cluster.analytical_platform_development.identity.0.oidc.0.issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.analytical_platform_development_eks_oidc_issuer.certificates[0].sha1_fingerprint]
}
