locals {
  name = "serj-test-export"
  tags = {
    environment = "serj-test"
  }
}

resource "aws_kms_key" "export" {
  description             = "KMS key for RDS export"
  deletion_window_in_days = 7

  tags = local.tags
}

data "aws_vpc" "selected" {
  id = "vpc-0b2907e67278ff255"
}

# Get all subnets with the tag "network" = "Private" in the selected VPC
data "aws_subnets" "private_subnets" {
  filter {
    name   = "tag:network"
    values = ["Private"]
  }

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

resource "aws_db_subnet_group" "export" {
  name       = local.name
  subnet_ids = data.aws_subnets.private_subnets.ids

  tags = local.tags
}

# Security group for the RDS instance
resource "aws_security_group" "db" {
  name        = local.name
  description = "Security group for RDS instance ${local.name}"
  vpc_id      = data.aws_vpc.selected.id

  tags = local.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
}

module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore"

  name                = local.name
  vpc_id              = data.aws_vpc.selected.id
  database_subnet_ids = data.aws_subnets.private_subnets.ids
  kms_key_arn         = aws_kms_key.export.arn

  tags = local.tags
}
