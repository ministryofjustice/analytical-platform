resource "kubernetes_namespace" "kedro" {
  metadata {
    name = "kedro"
  }
}
