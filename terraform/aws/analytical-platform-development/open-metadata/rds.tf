#tfsec:ignore:aws-rds-enable-performance-insights
module "airflow_rds" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier = "openmetadata-airflow"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t4g.medium"

  allocated_storage     = 32
  max_allocated_storage = 128

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username = "airflow"
  db_name  = "airflow"

  skip_final_snapshot = true
}

#tfsec:ignore:aws-rds-enable-performance-insights
module "rds" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier = "openmetadata"

  engine               = "mysql"
  engine_version       = "8.0"
  family               = "mysql8.0"
  major_engine_version = "8.0"
  instance_class       = "db.r6g.xlarge"

  allocated_storage     = 128
  max_allocated_storage = 512

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username = "openmetadata"
  db_name  = "openmetadata"

  skip_final_snapshot = true
}


#tfsec:ignore:aws-rds-enable-performance-insights
module "coder_rds" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry

  source  = "terraform-aws-modules/rds/aws"
  version = "6.1.0"

  identifier = "coder"

  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.t4g.medium"

  allocated_storage     = 10
  max_allocated_storage = 20

  multi_az               = true
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username = "coder"
  db_name  = "coder"

  skip_final_snapshot = true
}
