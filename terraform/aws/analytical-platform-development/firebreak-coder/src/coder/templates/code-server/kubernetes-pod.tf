resource "kubernetes_pod" "main" {
  count = data.coder_workspace.user.start_count

  metadata {
    name      = "coder-${lower(data.coder_workspace.user.owner)}-${lower(data.coder_workspace.user.name)}"
    namespace = "coder"
    labels = {
      "app.kubernetes.io/name"     = "coder-workspace"
      "app.kubernetes.io/instance" = "coder-workspace-${lower(data.coder_workspace.user.owner)}-${lower(data.coder_workspace.user.name)}"
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
  spec {
    security_context {
      run_as_user = "1000"
      fs_group    = "1000"
    }
    service_account_name = kubernetes_service_account.main.metadata[0].name
    container {
      name              = "dev"
      image             = "codercom/enterprise-base:ubuntu"
      image_pull_policy = "Always"
      command           = ["sh", "-c", coder_agent.main.init_script]
      security_context {
        run_as_user = "1000"
      }
      env {
        name  = "CODER_AGENT_TOKEN"
        value = coder_agent.main.token
      }
      resources {
        requests = {
          "cpu"    = "250m"
          "memory" = "512Mi"
        }
        limits = {
          "cpu"    = "${data.coder_parameter.cpu.value}"
          "memory" = "${data.coder_parameter.memory.value}Gi"
        }
      }
      volume_mount {
        mount_path = "/home/coder"
        name       = "home"
        read_only  = false
      }
    }

    volume {
      name = "home"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.home.metadata.0.name
        read_only  = false
      }
    }


    affinity {
      pod_anti_affinity {
        // This affinity attempts to spread out all workspace pods evenly across
        // nodes.
        preferred_during_scheduling_ignored_during_execution {
          weight = 1
          pod_affinity_term {
            topology_key = "kubernetes.io/hostname"
            label_selector {
              match_expressions {
                key      = "app.kubernetes.io/name"
                operator = "In"
                values   = ["coder-workspace"]
              }
            }
          }
        }
      }
    }
  }
}
