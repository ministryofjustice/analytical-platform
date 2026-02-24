locals {
  chainguard-credentials = jsondecode(data.aws_secretsmanager_secret_version.chainguard_image_pull_token.secret_string)
}

resource "kubernetes_secret_v1" "chainguard" {
  metadata {
    name      = "chainguard"
    namespace = "ingress-nginx"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "cgr.dev" = {
          username = local.chainguard-credentials["username"]
          password = local.chainguard-credentials["password"]
          auth     = base64encode("${local.chainguard-credentials["username"]}:${local.chainguard-credentials["password"]}")
        }
      }
    })
  }
}
