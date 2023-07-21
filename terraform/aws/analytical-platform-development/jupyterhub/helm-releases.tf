resource "helm_release" "jupyterhub" {
  name       = "jupyterhub"
  repository = "https://jupyterhub.github.io/helm-chart/"
  chart      = "jupyterhub"
  version    = "2.0.0"
  namespace  = kubernetes_namespace.jupyterhub.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/jupyterhub/values.yml.tftpl",
      {

        acm_certificate_arn = aws_acm_certificate_validation.jupyterhub.certificate_arn
        client_id           = jsondecode(data.aws_secretsmanager_secret_version.auth0.secret_string)["jupyterhub_auth0_clientid"]
        client_secret       = jsondecode(data.aws_secretsmanager_secret_version.auth0.secret_string)["jupyterhub_auth0_clientsecret"]
      }
    )
  ]
  wait    = true
  timeout = 600

  depends_on = [aws_acm_certificate_validation.jupyterhub]
}
