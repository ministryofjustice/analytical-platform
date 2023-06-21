resource "kubernetes_namespace" "open_metadata" {
  metadata {
    name = "open-metadata"
  }
}
