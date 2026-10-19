locals {
  analytical_platform_compute_environments = {
    development = {
      eks_oidc_id = "1972AFFBD0701A0D1FD291E34F7D1287"
    }
    test = {
      eks_oidc_id = "9FAFCA50C4DA68A8E75FD21EA53A4F2B"
    }
    production = {
      eks_oidc_id = "801920EDEF91E3CAB03E04C03A2DE2BB"
    }
  }

  # SHA-1 thumbprint of the CA for oidc.eks.eu-west-2.amazonaws.com
  eks_oidc_eu_west_2_thumbprint = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"

  # Data Platform Airflow EKS clusters
  # eks_oidc_id: aws eks describe-cluster --name <key>-airflow --query cluster.identity.oidc.issuer
  data_platform_airflow_environments = {
    data-platform-test = {
      eks_oidc_id = "525589099F444DB9628DC08D2FEFDAB0"
    }
  }
}
