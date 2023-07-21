resource "kubernetes_namespace" "coder" {
  metadata {
    name = "coder"
  }
}
