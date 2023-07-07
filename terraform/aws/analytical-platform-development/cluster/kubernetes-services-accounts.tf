resource "kubernetes_service_account" "airflow" {
  metadata {
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow"
  }
  image_pull_secret {
    name = "dockerhub"
  }
}
