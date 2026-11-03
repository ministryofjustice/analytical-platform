resource "aws_iam_openid_connect_provider" "analytical_platform_compute_dev_cluster_oidc_provider" {
  url = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-development-oidc-endpoint"]

  client_id_list = [
    "sts.amazonaws.com",
  ]
}

resource "aws_iam_openid_connect_provider" "analytical_platform_compute_cluster_oidc_provider" {
  url = jsondecode(data.aws_secretsmanager_secret_version.analytical_platform_compute_cluster_data.secret_string)["analytical-platform-compute-production-oidc-endpoint"]

  client_id_list = [
    "sts.amazonaws.com",
  ]

}
