resource "kubernetes_service_account" "main" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.user.owner)}-${lower(data.coder_workspace.user.name)}"
    namespace = "coder"
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::593291632749:role/alpha_user_${data.coder_parameter.github_account_name.value}"
    }
  }
}
