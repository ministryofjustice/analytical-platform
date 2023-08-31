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

output "kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "dev_node_group_standard" {
  cluster_name    = aws_eks_cluster.airflow_dev_eks_cluster.name
  node_group_name = "standard"
  node_role_arn   = aws_iam_role.airflow_dev_node_instance_role.arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_node_group" "dev_node_group_high_memory" {
  cluster_name    = aws_eks_cluster.airflow_dev_eks_cluster.name
  node_group_name = "high-memory"
  node_role_arn   = aws_iam_role.airflow_dev_node_instance_role.arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  scaling_config {
    desired_size = 0
    max_size     = 2
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  taint {
    key = "high-memory"
    value = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    high-memory = "true"
  }
}

