resource "helm_release" "coder" {
  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "0.27.1"
  namespace  = kubernetes_namespace.coder.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/coder/values.yml.tftpl",
      {
        acm_certificate_arn       = aws_acm_certificate_validation.coder.certificate_arn
        coder_access_url          = "coder.data-platform.moj.woffenden.dev"
        coder_db_url_secret       = kubernetes_secret.coder_rds_connection_url.metadata[0].name
        coder_db_url_key          = "url"
        oidc_issuer_url_secret    = kubernetes_secret.coder_azuread_issuer_url.metadata[0].name
        oidc_client_id_secret     = kubernetes_secret.coder_azuread_client_id.metadata[0].name
        oidc_client_secret_secret = kubernetes_secret.coder_azuread_client_secret.metadata[0].name
        oidc_email_domain         = "justice.gov.uk"
        oidc_sign_in_text         = "Sign in with Microsoft 365"
        oidc_icon_url             = "https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Microsoft_logo.svg/512px-Microsoft_logo.svg.png"
      }
    )
  ]
  wait    = true
  timeout = 600

  depends_on = [aws_acm_certificate_validation.coder]
}
