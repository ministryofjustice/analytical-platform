#tfsec:ignore:aws-rds-enable-performance-insights
module "coder_rds" {
  #checkov:skip=CKV_TF_1:Module is from Terraform registry
  #checkov:skip=CKV_AWS_129:PoC only
  #checkov:skip=CKV_AWS_133:PoC only
  #checkov:skip=CKV_AWS_293:PoC only
  #checkov:skip=CKV_AWS_118:PoC only
  #checkov:skip=CKV_AWS_353:PoC only
  #checkov:skip=CKV_AWS_338:PoC only
  #checkov:skip=CKV2_AWS_60:PoC only

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
  db_subnet_group_name   = local.rds_subnet_group_name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  username                    = "coder"
  db_name                     = "coder"
  manage_master_user_password = false
  password                    = random_password.coder_rds_password.result

  skip_final_snapshot = true
}
