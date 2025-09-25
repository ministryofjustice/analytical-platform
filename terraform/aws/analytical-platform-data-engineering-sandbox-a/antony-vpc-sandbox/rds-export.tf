
# Security group for the RDS instance
# checkov:skip=CKV2_AWS_5: Attached to VPC
resource "aws_security_group" "database" {
  name        = "antony-vpc-sandbox-sg"
  description = "Security group for RDS export instance"
  vpc_id      = module.vpc.vpc_id

  tags = var.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "database_rule" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  security_group_id = aws_security_group.database.id
  description       = "Allow Postgres access from VPC"
  cidr_blocks       = [module.vpc.vpc_cidr_block]
}
# checkov:skip=CKV_TF_1: Pointing to branch name whilst in development, will change to commit hash once in main
# checkov:skip=CKV_TF_2: Pointing to branch name whilst in development, will change to commit hash once in main
module "rds_export_dev" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=ppud-rds-export-split"

  providers = {
    aws = aws
  }

  name                  = "antony-rds-export"
  vpc_id                = module.vpc.vpc_id
  database_subnet_ids   = var.database_subnet_ids
  kms_key_arn           = var.kms_key_arn
  master_user_secret_id = aws_secretsmanager_secret_version.vpc_master_user.arn
  database_refresh_mode = "incremental"

  tags = var.tags

}
