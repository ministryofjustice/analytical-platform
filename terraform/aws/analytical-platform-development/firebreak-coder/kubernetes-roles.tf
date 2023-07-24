resource "kubernetes_role" "coder_workspace_perms_extended" {
  metadata {
    name      = "coder-workspace-perms-extended"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts"]
    verbs      = ["create", "get", "list", "watch", "delete"]
  }
}
