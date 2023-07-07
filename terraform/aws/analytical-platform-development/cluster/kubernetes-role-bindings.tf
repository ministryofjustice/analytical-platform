resource "kubernetes_role_binding" "airflow" {
  metadata {
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.airflow.metadata[0].name
  }
  subject {
    kind = "User"
    name = kubernetes_service_account.airflow.metadata[0].name
  }
}
