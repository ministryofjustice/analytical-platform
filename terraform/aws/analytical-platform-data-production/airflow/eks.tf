resource "aws_eks_cluster" "airflow_dev_eks_cluster" {
  name     = "airflow-dev"
  role_arn = var.dev_eks_role_arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.24"

  vpc_config {
    subnet_ids          = aws_subnet.private_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids  = ["sg-0bcd3cf5dc6d7b314"]
  }
}


output "endpoint" {
  value = aws_eks_cluster.airflow_dev_eks_cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data
}
