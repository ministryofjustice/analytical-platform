##################################################
# Auth0
##################################################

resource "aws_eks_identity_provider_config" "auth0" {
  cluster_name = module.eks.cluster_id

  oidc {
    client_id                     = auth0_client.controlpanel.client_id
    identity_provider_config_name = "Auth0"
    issuer_url                    = "https://${var.resource_prefix}-analytics-moj.eu.auth0.com/"
    groups_claim                  = "https://api.${var.resource_prefix}.mojanalytics.xyz/claims/groups"
    username_claim                = "nickname"
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
}
