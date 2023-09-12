resource "aws_eks_cluster" "airflow_dev_eks_cluster" {
  name     = var.dev_eks_cluster_name
  role_arn = var.dev_eks_role_arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.24"

  vpc_config {
    subnet_ids          = aws_subnet.dev_private_subnet[*].id
    public_access_cidrs = ["0.0.0.0/0"]
    security_group_ids  = [var.dev_cluster_additional_sg_id]
  }
}

resource "aws_security_group" "airflow_dev_cluster_additional_security_group" {
  name        = var.dev_cluster_additional_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_dev.id
  ingress {
    description     = "Allow pods to communicate with the cluster API Server"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.dev_cluster_node_sg_id]
  }
  egress {
    description = "Allow internet access."
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_security_group" "airflow_dev_cluster_node_security_group" {
  name        = var.dev_cluster_node_sg_name
  description = "Managed by Pulumi"
  vpc_id      = aws_vpc.airflow_dev.id

  ingress {
    description     = "Allow nodes to communicate with each other"
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = []
    self            = true
  }
  ingress {
    description     = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    protocol        = "tcp"
    from_port       = 1025
    to_port         = 65535
    security_groups = [var.dev_cluster_additional_sg_id]
  }
  ingress {
    description     = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [var.dev_cluster_additional_sg_id]
  }

  egress {
    description = "Allow internet access."
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

moved {
  from = aws_security_group.airflow_dev_security_group
  to   = aws_security_group.airflow_dev_cluster_additional_security_group
}

import {
  to = aws_security_group.airflow_dev_cluster_node_security_group
  id = "sg-01930457ae391c7f0"
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
  subnet_ids      = aws_subnet.dev_private_subnet[*].id

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
  subnet_ids      = aws_subnet.dev_private_subnet[*].id

  scaling_config {
    desired_size = 0
    max_size     = 2
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
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

######################################
########### EKS PRODUCTION ###########
######################################

resource "aws_eks_cluster" "airflow_prod_eks_cluster" {
  name     = var.prod_eks_cluster_name
  role_arn = var.prod_eks_role_arn
  enabled_cluster_log_types = ["api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler",
  ]
  version = "1.24"

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
    description = "Allow internet access."
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}

moved {
  from = aws_security_group.airflow_prod_security_group
  to   = aws_security_group.airflow_prod_cluster_additional_security_group
}

import {
  to = aws_security_group.airflow_prod_cluster_additional_security_group
  id = "sg-0f73e78564012634a"
}

output "prod_endpoint" {
  value = aws_eks_cluster.airflow_prod_eks_cluster.endpoint
}

output "prod_kubeconfig_certificate_authority_data" {
  value = aws_eks_cluster.airflow_prod_eks_cluster.certificate_authority[0].data
}

resource "aws_eks_node_group" "prod_node_group_standard" {
  cluster_name    = aws_eks_cluster.airflow_prod_eks_cluster.name
  node_group_name = "standard"
  node_role_arn   = aws_iam_role.airflow_prod_node_instance_role.arn
  subnet_ids      = aws_subnet.prod_private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 25
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }
}

resource "aws_eks_node_group" "prod_node_group_high_memory" {
  cluster_name    = aws_eks_cluster.airflow_prod_eks_cluster.name
  node_group_name = "high-memory"
  node_role_arn   = aws_iam_role.airflow_prod_node_instance_role.arn
  subnet_ids      = aws_subnet.prod_private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
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
