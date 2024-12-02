resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  replication_subnet_group_description = "Subnet group for DMS replication instances"
  replication_subnet_group_id          = "${data.aws_region.current.name}-${var.environment}"

  # these would come from the core stack once created
  subnet_ids = var.dms_replication_instance.subnet_ids

  tags = {
    Name        = "${data.aws_region.current.name}-${var.environment}"
    application = "Data Engineering"
  }
}

resource "aws_dms_replication_instance" "instance" {
  allocated_storage            = var.dms_replication_instance.allocated_storage
  auto_minor_version_upgrade   = true
  availability_zone            = var.dms_replication_instance.availability_zone
  engine_version               = var.dms_replication_instance.engine_version
  kms_key_arn                  = var.dms_replication_instance.kms_key_arn
  multi_az                     = var.dms_replication_instance.multi_az
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible          = false
  replication_instance_class   = var.dms_replication_instance.replication_instance_class
  replication_instance_id      = var.dms_replication_instance.replication_instance_id
  replication_subnet_group_id  = aws_dms_replication_subnet_group.replication_subnet_group.id
  vpc_security_group_ids       = var.dms_replication_instance.vpc_security_group_ids

  tags = {
    Name = var.dms_replication_instance.replication_instance_id
  }
}
