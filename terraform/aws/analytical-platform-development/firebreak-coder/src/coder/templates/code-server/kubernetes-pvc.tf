resource "kubernetes_persistent_volume_claim" "home" {
  metadata {
    name      = "coder-${lower(data.coder_workspace.user.owner)}-${lower(data.coder_workspace.user.name)}-home"
    namespace = "coder"
    labels = {
      "app.kubernetes.io/name"     = "coder-pvc"
      "app.kubernetes.io/instance" = "coder-pvc-${lower(data.coder_workspace.user.owner)}-${lower(data.coder_workspace.user.name)}"
      "app.kubernetes.io/part-of"  = "coder"
      // Coder specific labels.
      "com.coder.resource"       = "true"
      "com.coder.workspace.id"   = data.coder_workspace.user.id
      "com.coder.workspace.name" = data.coder_workspace.user.name
      "com.coder.user.id"        = data.coder_workspace.user.owner_id
      "com.coder.user.username"  = data.coder_workspace.user.owner
    }
    annotations = {
      "com.coder.user.email" = data.coder_workspace.user.owner_email
    }
  }
  wait_until_bound = false
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "${data.coder_parameter.home_disk_size.value}Gi"
      }
    }
  }
}
