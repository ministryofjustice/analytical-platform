resource "aws_db_subnet_group" "dms_test" {
  name       = "dms_test"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_security_group" "rds_instance" {
  name        = "dms-test"
  description = "Security group for DMS test RDS instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_db_instance" "dms_test" {
  identifier                  = "dms-test"
  allocated_storage           = 10
  db_name                     = "DMSTEST"
  engine                      = "oracle-ee"
  engine_version              = "19.0.0.0.ru-2024-10.rur-2024-10.r1"
  instance_class              = "db.t3.small"
  username                    = "admin"
  manage_master_user_password = true
  backup_retention_period     = 10
  parameter_group_name        = "default.oracle-ee-19"
  skip_final_snapshot         = true
  db_subnet_group_name        = aws_db_subnet_group.dms_test.name
  vpc_security_group_ids      = [aws_security_group.rds_instance.id]
}
