# Security group for the RDS instance
# checkov:skip=CKV2_AWS_5: Attached to VPC
resource "aws_security_group" "db" {
  name        = local.name
  description = "Security group for RDS instance ${local.name}"
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
# checkov:skip=CKV_TF_1: Pointing to branch name whilst in development, will change to commit hash once in main
# checkov:skip=CKV_TF_2: Pointing to branch name whilst in development, will change to commit hash once in main
module "rds_export_dev" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=ppud-rds-export-split"

  providers = {
    aws = aws
  }

  name                  = local.name
  database_refresh_mode = "incremental"
  vpc_id                = module.vpc_dev.vpc_id
  database_subnet_ids   = module.vpc_dev.private_subnets
  kms_key_arn           = module.rds_export_kms_dev.key_arn
  master_user_secret_id = module.rds_export_secret.secret_arn

  tags = var.tags
}
