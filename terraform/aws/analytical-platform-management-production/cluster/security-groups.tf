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
