# resource "kubernetes_namespace" "dev_kube2iam" {
#   provider = kubernetes.dev-airflow-cluster
#   metadata {
#     annotations = {
#       "iam.amazonaws.com/allowed-roles" = jsonencode(["*"])
#     }
#     labels = {
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#     name = "kube2iam-system"
#   }
#   timeouts {}
# }

# resource "kubernetes_namespace" "dev_airflow" {
#   provider = kubernetes.dev-airflow-cluster
#   metadata {

#     name = "airflow"
#     annotations = {
#       "iam.amazonaws.com/allowed-roles" = jsonencode(["airflow_dev*"])
#     }
#     labels = {
#       "app.kubernetes.io/managed-by" = "Terraform"
#     }
#   }
#   timeouts {}
# }

# resource "kubernetes_namespace" "kyverno_dev" {
#   provider = kubernetes.dev-airflow-cluster
#   metadata {
#     name = "kyverno"
#     labels = {
#       "app.kubernetes.io/managed-by" = "Terraform"
#     }
#   }
#   timeouts {}
# }

# resource "kubernetes_namespace" "cluster_autoscaler_system" {
#   provider = kubernetes.dev-airflow-cluster
#   metadata {
#     name = "cluster-autoscaler-system"
#     annotations = {
#       "iam.amazonaws.com/allowed-roles" = jsonencode(["airflow-dev-cluster-autoscaler-role"])
#     }
#     labels = {
#       "app.kubernetes.io/managed-by" = "Terraform"
#     }
#   }
#   timeouts {}
# }

moved {
  from = kubernetes_namespace.cluster-autoscaler-system
  to   = kubernetes_namespace.cluster_autoscaler_system
}
