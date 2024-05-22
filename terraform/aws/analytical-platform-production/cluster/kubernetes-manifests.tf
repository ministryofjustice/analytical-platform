resource "kubernetes_manifest" "nvidia_device_plugin" {
  manifest = yamldecode(file("src/kubernetes/nvidia-device-plugin.yml"))
}
