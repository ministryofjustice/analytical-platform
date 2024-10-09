resource "kubernetes_namespace" "aws_observability" {
  metadata {
    name = "aws-observability"
  }
}
