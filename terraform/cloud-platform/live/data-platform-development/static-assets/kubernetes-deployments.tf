resource "kubernetes_deployment" "static_assets" {
  #checkov:skip=CKV_K8S_22:NGINX requires write access to /tmp/proxy_temp - will look at making /tmp/proxy_temp an ephemeral volume
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
          name              = "static-assets"
          image             = "ghcr.io/ministryofjustice/data-platform-static-assets@sha256:0b55c9eaecbd0fb517a4d32bedee9e682335eb74cadefba0a31cb874b3e1750d"
          image_pull_policy = "Always"
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
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          security_context {
            allow_privilege_escalation = false
            run_as_non_root            = true
            run_as_user                = 101
            read_only_root_filesystem  = false
            capabilities {
              drop = [
                "ALL",
                "NET_RAW"
              ]
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
