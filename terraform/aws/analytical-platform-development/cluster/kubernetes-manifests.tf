resource "kubernetes_manifest" "nvidia_device_plugin" {
  manifest = yamldecode(file("src/kubernetes/nvidia-device-plugin.yml"))
}

# resource "kubernetes_manifest" "nvidia_gpu_slicing" {
#   manifest = yamldecode(file("src/kubernetes/nvidia-gpu-slicing.yml"))
# }
