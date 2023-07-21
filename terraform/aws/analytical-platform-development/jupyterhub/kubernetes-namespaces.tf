resource "kubernetes_namespace" "jupyterhub" {
  metadata {
    name = "jupyterhub"
  }
}
