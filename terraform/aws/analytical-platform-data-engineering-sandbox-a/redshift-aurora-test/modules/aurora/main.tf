terraform {
  required_version = "~> 1.5"
}

# -----------------------------------------------------------------------------
# Aurora PostgreSQL Cluster
# -----------------------------------------------------------------------------
module "aurora" {
  # checkov:skip=CKV_TF_1:Module registry does not support commit hashes for versions
  source  = "terraform-aws-modules/rds-aurora/aws"
  version = "9.4.0"

  name            = var.cluster_name
  engine          = "aurora-postgresql"
  engine_version  = var.engine_version
  master_username = var.master_username
  database_name   = var.database_name

  # Managed master password
  manage_master_user_password                            = true
  master_user_password_rotation_automatically_after_days = 30

  # Instance configuration
  instance_class = var.instance_class
  instances = {
    primary = {
      identifier = "${var.cluster_name}-primary"
    }
  }

  # Network configuration
  vpc_id                 = var.vpc_id
  create_db_subnet_group = true
  subnets                = var.database_subnet_ids
  db_subnet_group_name   = "${var.cluster_name}-subnet-group"

  # Security
  create_security_group  = false
  vpc_security_group_ids = [aws_security_group.aurora.id]
  storage_encrypted      = true
  kms_key_id             = var.kms_key_arn

  # IAM authentication
  iam_database_authentication_enabled = true

  # Backup and maintenance
  backup_retention_period      = var.backup_retention_period
  preferred_maintenance_window = "sun:05:00-sun:06:00"
  preferred_backup_window      = "03:00-04:00"
  deletion_protection          = var.deletion_protection
  skip_final_snapshot          = var.skip_final_snapshot
  apply_immediately            = true

  # Monitoring
  create_monitoring_role          = true
  monitoring_interval             = 60
  enabled_cloudwatch_logs_exports = ["postgresql"]
  create_cloudwatch_log_group     = true
  performance_insights_enabled    = true

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Security Group for Aurora
# -----------------------------------------------------------------------------
resource "aws_security_group" "aurora" {
  # checkov:skip=CKV2_AWS_5:Attached to the Aurora cluster via module.aurora vpc_security_group_ids.
  name_prefix = "${var.cluster_name}-aurora-"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-aurora"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow PostgreSQL access from within VPC
resource "aws_security_group_rule" "aurora_ingress_vpc" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  security_group_id = aws_security_group.aurora.id
  description       = "PostgreSQL access from VPC"
}

# Allow egress to S3 via prefix list (for data export functionality)
data "aws_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"
}

resource "aws_security_group_rule" "aurora_egress_s3" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
  security_group_id = aws_security_group.aurora.id
  description       = "HTTPS to S3"
}
