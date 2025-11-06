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

module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=00ad82af97df2ba70973b0f9db9b35249ddf8bcc"

  providers = {
    aws = aws
  }

  name                     = local.name
  database_refresh_mode    = "full"
  vpc_id                   = module.vpc_dev.vpc_id
  database_subnet_ids      = module.vpc_dev.private_subnets
  kms_key_arn              = module.rds_export_kms_dev.key_arn
  master_user_secret_id    = module.rds_export_secret.secret_arn
  environment              = var.tags["environment"]
  output_parquet_file_size = 50
  db_name                  = "ppud_dev"

  tags = var.tags
}
