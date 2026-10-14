# Security group for the RDS instance
resource "aws_security_group" "db" {
  # checkov:skip=CKV2_AWS_5: Attached to VPC
  name        = "${local.name}-${local.env}"
  description = "Security group for RDS instance ${local.name}-${local.env}"
  vpc_id      = module.vpc_dev.vpc_id

  tags = var.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = [module.vpc_dev.vpc_cidr_block]
  description       = "Allow access to the RDS instance from the VPC"
}
