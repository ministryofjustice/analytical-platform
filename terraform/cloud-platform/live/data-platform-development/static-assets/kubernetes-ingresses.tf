resource "kubernetes_ingress_v1" "static_assets" {
  metadata {
    name      = "static-assets"
    namespace = "data-platform-development"
    labels = {
      app = "static-assets"
    }
    annotations = {
      "external-dns.alpha.kubernetes.io/set-identifier" = "static-assets-data-platform-development-green"
      "external-dns.alpha.kubernetes.io/aws-weight"     = "100"
    }
  }
  spec {
    ingress_class_name = "default"
    tls {
      hosts = ["data-platform-development-static-assets.apps.live.cloud-platform.service.justice.gov.uk"]
    }
    rule {
      host = "data-platform-development-static-assets.apps.live.cloud-platform.service.justice.gov.uk"
      http {
        path {
          path      = "/"
          path_type = "ImplementationSpecific"
          backend {
            service {
              name = "static-assets"
              port {
                number = 8080
              }
            }
          }
        }
      }
    }
  }
}
