/*
This is commented out because it didn't work.
It wouldn't schedule properly, so we switched to applying the "simple" option with out taints and tolerations
resource "helm_release" "nvidia_device_plugin" {
  name       = "nvidia-device-plugin"
  repository = "https://nvidia.github.io/k8s-device-plugin"
  chart      = "nvidia-device-plugin"
  version    = "0.15.0"
  namespace  = "kube-system"
  values = [
    templatefile(
      "${path.module}/src/helm/nvidia/values.yml.tftpl", {}
    )
  ]
}
*/
