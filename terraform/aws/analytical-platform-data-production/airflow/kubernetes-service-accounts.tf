resource "kubernetes_service_account" "airflow" {
  metadata {
    namespace = kubernetes_namespace.dev_airflow.metadata[0].name
    name      = "airflow"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.airflow_dev_monitoring_iam_role.iam_role_arn
    }
  }
}
