resource "kubernetes_manifest" "cert_manager_cluster_issuers" {
  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
    }
    "spec" = {
      "acme" = {
        "email"  = "data-platform-tech+certificates@digital.justice.gov.uk"
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "solvers" = [
          {
            "dns01" = {
              "cnameStrategy" = "Follow"
              "route53" = {
                "region"       = data.aws_region.current.name
                "hostedZoneID" = aws_route53_zone.data_platform_moj_woffenden_dev.zone_id
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager]
}
