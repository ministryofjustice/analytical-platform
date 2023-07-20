resource "helm_release" "coder" {
  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  version    = "0.26.1"
  namespace  = kubernetes_namespace.coder.metadata[0].name
  values = [
    templatefile(
      "${path.module}/src/helm/coder/values.yml.tftpl",
      {
        acm_certificate_arn = aws_acm_certificate_validation.coder.certificate_arn
        coder_access_url    = "coder.data-platform.moj.woffenden.dev"
        coder_db_url_secret = kubernetes_secret.coder_rds_connection_url.metadata[0].name
      }
    )
  ]
  wait    = true
  timeout = 600

  depends_on = [aws_acm_certificate_validation.coder]
}
