resource "aws_iam_openid_connect_provider" "open_metadata" {
  provider = aws.analytical-platform-data-production

  url             = data.aws_eks_cluster.open_metadata.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.open_metadata_eks_oidc_issuer.certificates[0].sha1_fingerprint]
}
