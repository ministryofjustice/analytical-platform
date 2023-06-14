output "eks_cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "eks_config_map_aws_auth" {
  value = module.eks.config_map_aws_auth
}
