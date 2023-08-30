resource "aws_eks_cluster" "airflow_dev_eks_cluster" {
  name     = "airflow-dev"
  role_arn = aws_iam_role.airflow_dev_cluster_role.arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.24"

  vpc_config {
    subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id, aws_subnet.private_subnet[2].id]
  }
}


output "endpoint" {
  value = aws_eks_cluster.airflow_dev_eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data
}
