##################################################
# EFS
##################################################

resource "aws_security_group" "efs" {
  # Cannot be renamed as it's attached to the EFS mount target network interfaces
  name        = "MyEfsSecurityGroup"
  description = "EFS security group to allow access to home directories"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.vpc_private_subnets
  }
}

##################################################
# Amazon Managed Prometheus
##################################################

resource "aws_security_group" "aps" {
  name        = "aps"
  description = "allow EKS cluster to access VPC endpoint for managed prometheus"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.eks.worker_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################################
# EKS Control Plane
##################################################

resource "aws_security_group" "controlplane" {
  name        = "cluster_security_group"
  description = "control plane ingress"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "kube-controller-manager"
    from_port   = 10257
    to_port     = 10257
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "kubelet API"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "kube-scheduler"
    from_port   = 10259
    to_port     = 10259
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "etcd server client API"
    from_port   = 2379
    to_port     = 2379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
}
