resource "kubernetes_service_account" "airflow" {
  metadata {
    namespace = kubernetes_namespace.dev_airflow.metadata[0].name
    name      = "airflow"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::593291632749:role/airflow_monitoring_dev"
    }
  }
}
