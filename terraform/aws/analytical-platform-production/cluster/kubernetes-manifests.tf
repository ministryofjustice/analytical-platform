resource "kubernetes_manifest" "nvidia_device_plugin" {
  manifest = yamldecode(file("src/kubernetes/nvidia-device-plugin.yml"))
}

resource "kubernetes_manifest" "nvidia_gpu_slicing" {
  manifest = yamldecode(file("src/kubernetes/nvidia-gpu-slicing.yml"))
}

resource "kubernetes_manifest" "nvidia_cluster_role" {
  manifest = yamldecode(file("src/kubernetes/nvidia-cluster-role.yml"))
}

resource "kubernetes_manifest" "nvidia_cluster_role_binding" {
  manifest = yamldecode(file("src/kubernetes/nvidia-cluster-role-binding.yml"))
}

resource "kubernetes_manifest" "nvidia_service_account" {
  manifest = yamldecode(file("src/kubernetes/nvidia-service-account.yml"))
}

resource "kubernetes_manifest" "prometheus_operator_crds" {
  for_each = data.http.prometheus_operator_crds

  manifest = yamldecode(each.value.response_body)
}
