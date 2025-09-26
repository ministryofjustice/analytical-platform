
# Security group for the RDS instance
resource "aws_security_group" "database" {
  #checkov:skip=CKV2_AWS_5: Attached to VPC
  name        = "antony-vpc-sandbox-sg"
  description = "Security group for RDS export instance"
  vpc_id      = module.vpc.vpc_id

  tags = var.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "database_rule" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.database.id
  description       = "Allow rds database access from VPC"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}
module "rds_export_dev" {
  # checkov:skip=CKV_TF_1: Pointing to branch name whilst in development, will change to commit hash once in main
  # checkov:skip=CKV_TF_2: Pointing to branch name whilst in development, will change to commit hash once in main

  source = "github.com/ministryofjustice/terraform-rds-export?ref=ppud-rds-export-split"

  providers = {
    aws = aws
  }

  name                  = "antony-rds-export"
  vpc_id                = module.vpc.vpc_id
  database_subnet_ids   = module.vpc.private_subnets
  kms_key_arn           = module.antony-vpc-sandbox-kms.key_arn
  master_user_secret_id = aws_secretsmanager_secret_version.vpc_master_user.arn
  database_refresh_mode = "incremental"

  tags = var.tags

}
