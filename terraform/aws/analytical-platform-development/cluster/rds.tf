##################################################
# Control Panel RDS
##################################################

module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.2.0"

  identifier          = local.rds_identifier
  engine              = var.rds_engine
  family              = var.rds_family
  engine_version      = var.rds_engine_version
  instance_class      = var.rds_instance_class
  allocated_storage   = var.rds_allocated_storage
  deletion_protection = var.rds_deletion_protection
  multi_az            = var.rds_multi_az
  storage_encrypted   = var.rds_storage_encrypted
  snapshot_identifier = var.rds_snapshot_identifier
  maintenance_window  = var.rds_maintenance_window
  backup_window       = var.rds_backup_window

  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [module.eks.worker_security_group_id]

  db_name  = var.rds_db_name
  username = local.rds_credentials.user
  password = local.rds_credentials.password
  port     = var.rds_port

  monitoring_interval  = var.rds_monitoring_interval
  monitoring_role_name = var.rds_monitoring_role_name

  create_db_option_group      = false
  create_db_subnet_group      = true
  create_monitoring_role      = true
  manage_master_user_password = false

  parameters = var.rds_paramaters

  timeouts = var.rds_timeouts

  tags = {
    Name = local.rds_identifier
  }
}
