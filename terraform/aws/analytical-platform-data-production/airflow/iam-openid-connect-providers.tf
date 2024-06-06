resource "aws_iam_openid_connect_provider" "analytical_platform_development" {
  url             = data.aws_eks_cluster.analytical_platform_development.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.analytical_platform_development_eks_oidc_issuer.certificates[0].sha1_fingerprint]
}

resource "aws_iam_openid_connect_provider" "airflow_dev" {
  url             = aws_eks_cluster.airflow_dev_eks_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.airflow_dev_eks_cluster.certificates[0].sha1_fingerprint]
}

import {
  to = aws_iam_openid_connect_provider.airflow_dev
  id = "arn:aws:iam::593291632749:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/59429428EBABBB9F911A173D7B8E8179"
}
