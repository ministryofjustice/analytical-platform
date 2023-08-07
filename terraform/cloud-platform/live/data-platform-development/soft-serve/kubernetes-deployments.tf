resource "kubernetes_deployment" "soft_serve" {
  metadata {
    name = "soft-serve"
    namespace = data.aws_secretsmanager_secret_version.cloud_platform_live_data_platform_development_namespace.secret_string
    labels = {
      app = "soft-serve"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "soft-serve"
      }
    }
    template {
      metadata {
        labels = {
          app = "soft-serve"
        }
      }
      spec {
        container {
          image = "garyh9/soft-serve:latest"
          name  = "soft-serve"
          image_pull_policy = "Always"

          port {
            container_port = 23231
          }

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}
