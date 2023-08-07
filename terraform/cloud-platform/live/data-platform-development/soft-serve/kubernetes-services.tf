resource "kubernetes_service" "soft_serve" {
  metadata {
    name      = "soft-serve"
    namespace = data.aws_secretsmanager_secret_version.cloud_platform_live_data_platform_development_namespace.secret_string
    labels = {
      app = "soft-serve"
    }
  }

  spec {
    selector = {
      app = kubernetes_deployment.soft_serve.spec.0.template.0.metadata[0].labels.app
    }

    port {
      port        = 23231
      target_port = 23231
    }

    type = "ClusterIP"
  }
}
