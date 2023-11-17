resource "kubernetes_service" "static_assets" {
  metadata {
    name      = "static-assets"
    namespace = "data-platform-development"
    labels = {
      app = "static-assets"
    }
  }
  spec {
    selector = {
      app = "static-assets"
    }
    type = "ClusterIP"
    port {
      name        = "http"
      port        = 8080
      target_port = 8080
    }
  }
}
