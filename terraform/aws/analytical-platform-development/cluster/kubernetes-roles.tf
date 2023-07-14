resource "kubernetes_role" "airflow" {
  metadata {
    namespace = kubernetes_namespace.airflow.metadata[0].name
    name      = "airflow"
  }
  rule {
    api_groups = [
      "",
      "apps",
      "batch",
      "extensions",
    ]
    resources = [
      "jobs",
      "pods",
      "pods/attach",
      "pods/exec",
      "pods/log",
      "pods/portforward",
      "secrets",
      "services"
    ]
    verbs = [
      "create",
      "delete",
      "describe",
      "get",
      "list",
      "patch",
      "update"
    ]
  }
}
