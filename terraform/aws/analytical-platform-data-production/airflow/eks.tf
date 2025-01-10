resource "aws_eks_cluster" "airflow_dev_eks_cluster" {
  name     = var.dev_eks_cluster_name
  role_arn = aws_iam_role.airflow_dev_eks_role.arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.28"

  vpc_config {
    subnet_ids          = aws_subnet.dev_private_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids  = [var.dev_cluster_additional_sg_id]
  }
}

# resource "aws_security_group" "airflow_dev_cluster_additional_security_group" {
#   name        = var.dev_cluster_additional_sg_name
#   description = "Managed by Pulumi"
#   vpc_id      = aws_vpc.airflow_dev.id
#   ingress {
#     description     = "Allow pods to communicate with the cluster API Server"
#     protocol        = "tcp"
#     from_port       = 443
#     to_port         = 443
#     security_groups = [var.dev_cluster_node_sg_id]
#   }
#   egress {
#     description = "Allow internet access."
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     to_port     = 0
#   }
# }

# resource "aws_security_group" "airflow_dev_cluster_node_security_group" {
#   name        = var.dev_cluster_node_sg_name
#   description = "Managed by Pulumi"
#   vpc_id      = aws_vpc.airflow_dev.id

#   ingress {
#     description     = "Allow nodes to communicate with each other"
#     protocol        = "-1"
#     from_port       = 0
#     to_port         = 0
#     security_groups = []
#     self            = true
#   }
#   ingress {
#     description     = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
#     protocol        = "tcp"
#     from_port       = 1025
#     to_port         = 65535
#     security_groups = [var.dev_cluster_additional_sg_id]
#   }
#   ingress {
#     description     = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
#     protocol        = "tcp"
#     from_port       = 443
#     to_port         = 443
#     security_groups = [var.dev_cluster_additional_sg_id]
#   }

#   egress {
#     description = "Allow internet access."
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#     from_port   = 0
#     to_port     = 0
#   }
# }

# output "endpoint" {
#   value = aws_eks_cluster.airflow_dev_eks_cluster.endpoint
# }

# output "kubeconfig_certificate_authority_data" {
#   value = aws_eks_cluster.airflow_dev_eks_cluster.certificate_authority[0].data
# }

# resource "aws_eks_node_group" "dev_node_group_standard" {
#   cluster_name    = aws_eks_cluster.airflow_dev_eks_cluster.name
#   node_group_name = "standard"
#   node_role_arn   = aws_iam_role.airflow_dev_node_instance_role.arn
#   subnet_ids      = aws_subnet.dev_private_subnet[*].id

#   launch_template {
#     id      = aws_launch_template.dev_standard.id
#     version = aws_launch_template.dev_standard.latest_version
#   }

#   scaling_config {
#     desired_size = 1
#     max_size     = 10
#     min_size     = 1
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   # Allow external changes without Terraform plan difference
#   lifecycle {
#     ignore_changes = [scaling_config[0].desired_size]
#   }
# }

# resource "aws_eks_node_group" "dev_node_group_high_memory" {
#   cluster_name    = aws_eks_cluster.airflow_dev_eks_cluster.name
#   node_group_name = "high-memory"
#   node_role_arn   = aws_iam_role.airflow_dev_node_instance_role.arn
#   subnet_ids      = aws_subnet.dev_private_subnet[*].id

#   launch_template {
#     id      = aws_launch_template.dev_high_memory.id
#     version = aws_launch_template.dev_high_memory.latest_version
#   }

#   scaling_config {
#     desired_size = 0
#     max_size     = 1
#     min_size     = 0
#   }

#   update_config {
#     max_unavailable = 1
#   }

#   # Allow external changes without Terraform plan difference
#   lifecycle {
#     ignore_changes = [scaling_config[0].desired_size]
#   }

#   taint {
#     key    = "high-memory"
#     value  = "true"
#     effect = "NO_SCHEDULE"
#   }

#   labels = {
#     high-memory = "true"
#   }
# }


# resource "kubernetes_config_map" "dev_aws_auth_configmap" {
#   provider = kubernetes.dev-airflow-cluster
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#     labels = {
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }

#   data = {
#     "mapRoles" = file("./files/dev/aws-auth-configmap.yaml")
#   }

# }

######################################
########### EKS PRODUCTION ###########
######################################

resource "aws_eks_cluster" "airflow_prod_eks_cluster" {
  name     = var.prod_eks_cluster_name
  role_arn = aws_iam_role.airflow_prod_eks_role.arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.28"

  vpc_config {
    subnet_ids          = aws_subnet.prod_private_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids  = [var.prod_cluster_additional_sg_id]
  }
}

resource "aws_security_group" "airflow_prod_cluster_additional_security_group" {
  name        = var.prod_cluster_additional_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_prod.id
  ingress {
    description     = "Allow pods to communicate with the cluster API Server"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.prod_node_sg_id]
  }
  egress {
    description     = "Allow internet access."
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    from_port       = 0
    to_port         = 0
    security_groups = []
  }
}

output "prod_endpoint" {
  value = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
}

output "prod_kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "prod_node_group_standard" {
  cluster_name    = aws_eks_cluster.airflow_prod_eks_cluster.name
  node_group_name = "new-standard"
  node_role_arn   = aws_iam_role.airflow_prod_node_instance_role.arn
  subnet_ids      = aws_subnet.prod_private_subnet[*].id

  launch_template {
    id      = aws_launch_template.prod_standard.id
    version = aws_launch_template.prod_standard.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 25
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

resource "aws_eks_node_group" "prod_node_group_high_memory" {
  cluster_name    = aws_eks_cluster.airflow_prod_eks_cluster.name
  node_group_name = "new-high-memory"
  node_role_arn   = aws_iam_role.airflow_prod_node_instance_role.arn
  subnet_ids      = aws_subnet.prod_private_subnet[*].id

  launch_template {
    id      = aws_launch_template.prod_high_memory.id
    version = aws_launch_template.prod_high_memory.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  taint {
    key    = "high-memory"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    high-memory = "true"
  }
}

resource "kubernetes_namespace" "kyverno_prod" {
  provider = kubernetes.prod-airflow-cluster
  metadata {
    name = "kyverno"
    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }
  timeouts {}
}

resource "aws_eks_addon" "kube_proxy_dev" {
  cluster_name                = var.dev_eks_cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.28.8-eksbuild.5"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni_dev" {
  cluster_name                = var.dev_eks_cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.1-eksbuild.3"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "coredns_dev" {
  cluster_name                = var.dev_eks_cluster_name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.11"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "kube_proxy_prod" {
  cluster_name                = var.prod_eks_cluster_name
  addon_name                  = "kube-proxy"
  addon_version               = "v1.28.8-eksbuild.5"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "vpc_cni_prod" {
  cluster_name                = var.prod_eks_cluster_name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.18.1-eksbuild.3"
  resolve_conflicts_on_create = "OVERWRITE"
}

resource "aws_eks_addon" "coredns_prod" {
  cluster_name                = var.prod_eks_cluster_name
  addon_name                  = "coredns"
  addon_version               = "v1.10.1-eksbuild.11"
  resolve_conflicts_on_create = "OVERWRITE"
}
