# Security group for the RDS instance
resource "aws_security_group" "db" {
  # checkov:skip=CKV2_AWS_5: Attached to VPC
  name        = "${local.name}-${local.env}"
  description = "Security group for RDS instance ${local.name}-${local.env}"
  vpc_id      = module.vpc.vpc_id

  tags = var.tags
}

# Allow access to the RDS instance from the VPC
resource "aws_security_group_rule" "db_ingress" {
  type              = "ingress"
  from_port         = 1433
  to_port           = 1433
  protocol          = "tcp"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = [module.vpc.vpc_cidr_block]
  description       = "Allow access to the RDS instance from the VPC"
}

module "rds_export" {
  source = "github.com/ministryofjustice/terraform-rds-export?ref=d8a7a1d03f212ac203112cf729d6c27d7030f42c"

  providers = {
    aws = aws
  }

  name                     = local.name
  database_refresh_mode    = "incremental"
  vpc_id                   = module.vpc.vpc_id
  database_subnet_ids      = module.vpc.private_subnets
  kms_key_arn              = module.rds_export_kms.key_arn
  master_user_secret_id    = module.rds_export_secret.secret_arn
  environment              = var.tags["environment"]
  output_parquet_file_size = 200
  db_name                  = "ppud_prod"

  tags = var.tags
}

# Create a resource to subscribe to SNS topic
# Slack notifications
resource "aws_sns_topic_subscription" "sfn_events" {
  topic_arn = module.rds_export.sns_topic_arn
  protocol  = "https"
  endpoint  = data.aws_secretsmanager_secret_version.slack_webhook.secret_string
}
