output "eks_cluster_oidc_issuer_url" {
  value = module.eks.cluster_oidc_issuer_url
}

output "eks_config_map_aws_auth" {
  value = module.eks.config_map_aws_auth
}

output "control_panel_api_iam_role_arn" {
  value = module.iam_assumable_role_control_panel_api.iam_role_arn
}
