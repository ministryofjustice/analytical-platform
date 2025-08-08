locals {
  name = "ppud-dev"
}

data "aws_vpc" "selected" {
  id     = "vpc-0b9d7482fd1f0c601"
  region = "eu-west-1"
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

  tags = var.tags
}

# Security group for the RDS instance
resource "aws_security_group" "db" {
  name        = local.name
  description = "Security group for RDS instance ${local.name}"
  vpc_id      = data.aws_vpc.selected.id

  tags = var.tags
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
  source = "github.com/ministryofjustice/terraform-rds-export?ref=sql-backup-restore-rds-updates"

  providers = {
    aws = aws
  }

  name                  = local.name
  vpc_id                = data.aws_vpc.selected.id
  database_subnet_ids   = data.aws_subnets.private_subnets.ids
  kms_key_arn           = module.rds_export_kms_dev.key_arn
  master_user_secret_id = aws_secretsmanager_secret.rds_export_dev.arn

  tags = var.tags
}