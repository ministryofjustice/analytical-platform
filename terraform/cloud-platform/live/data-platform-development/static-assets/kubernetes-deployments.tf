resource "kubernetes_deployment" "static_assets" {
  metadata {
    name      = "static-assets"
    namespace = "data-platform-development"
    labels = {
      app = "static-assets"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "static-assets"
      }
    }
    template {
      metadata {
        labels = {
          app = "static-assets"
        }
      }
      spec {
        container {
          name  = "static-assets"
          image = "ghcr.io/ministryofjustice/data-platform-static-assets:0.0.1"
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
          port {
            container_port = 8080
          }
        }

      }
    }
  }
}
