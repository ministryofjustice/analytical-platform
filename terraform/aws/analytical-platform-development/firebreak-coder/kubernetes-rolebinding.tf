resource "kubernetes_role_binding" "coder_workspace_perms_extended" {
  metadata {
    name      = "coder-workspace-perms-extended"
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.coder_workspace_perms_extended.metadata[0].name
  }
  subject {
    kind      = "ServiceAccount"
    name      = data.kubernetes_service_account.coder.metadata[0].name
    namespace = kubernetes_namespace.coder.metadata[0].name
  }
}
