resource "kubernetes_secret_v1" "chainguard" {
  metadata {
    name      = "chainguard"
    namespace = "ingress-nginx"
  }

  type = "Opaque"

  data = {
    "token" = data.aws_secretsmanager_secret_version.chainguard_image_pull_token.secret_string
  }
}
