removed {
  from = kubernetes_namespace.kyverno_prod

  lifecycle {
    destroy = false
  }
}

removed {
  from = helm_release.kyverno_prod

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.kyverno_policy_disallow_escalation_prod

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.kyverno_policy_run_as_non_root_prod

  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.kyverno_policy_run_as_non_root_user_prod

  lifecycle {
    destroy = false
  }
}
