resource "kubernetes_service_account" "airflow" {
  metadata {
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::593291632749:role/airflow-analytical-platform-development"
    }
  }
  image_pull_secret {
    name = "dockerhub"
  }
}
