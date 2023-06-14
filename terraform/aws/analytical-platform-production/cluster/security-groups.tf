##################################################
# EFS
##################################################

resource "aws_security_group" "efs" {
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
# TODO: why wasn't this done?
##################################################
