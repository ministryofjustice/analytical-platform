##################################################
# Data Platform Airflow EKS clusters
##################################################
# Workflow IRSA roles for Data Platform Airflow live in this account, but the
# clusters run in Data Platform accounts. STS needs an OIDC provider in this
# account for each cluster's issuer to accept the pods' web identity tokens.
# Same approach as the cloud_platform provider in
# analytical-platform-production/cluster/iam-openid-connect-providers.tf.

resource "aws_iam_openid_connect_provider" "data_platform_airflow" {
  for_each = local.data_platform_airflow_environments

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [local.eks_oidc_eu_west_2_thumbprint]
  url             = "https://oidc.eks.eu-west-2.amazonaws.com/id/${each.value.eks_oidc_id}"

  tags = {
    Name = "${each.key}-airflow"
  }
}
