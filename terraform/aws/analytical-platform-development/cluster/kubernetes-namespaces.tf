resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}
