resource "aws_security_group" "replication_instance" {
  name        = "${var.db}-${data.aws_region.current.name}-${var.environment}"
  description = "Security group for DMS replication instances. Managed by Terraform"
  vpc_id      = var.vpc_id
  tags = merge(
    { Name = "${var.db}-${data.aws_region.current.name}-${var.environment}" },
    var.tags
  )
}

resource "aws_vpc_security_group_ingress_rule" "replication_instance_inbound" {
  security_group_id = aws_security_group.replication_instance.id

  description = "Allow inbound traffic to DMS replication instances (Check if it is necessary)"
  cidr_ipv4   = var.dms_replication_instance.inbound_cidr
  from_port   = 1521
  ip_protocol = "tcp"
  to_port     = 1521
  tags = merge(
    var.tags,
    { application = "Data Engineering" }
  )
}

resource "aws_vpc_security_group_egress_rule" "replication_instance_outbound" {
  security_group_id = aws_security_group.replication_instance.id
  description       = "Allow outbound traffic from DMS replication instances"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
  tags = merge(
    var.tags,
    { application = "Data Engineering" }
  )
}

# Being moved out of the modules as it is reused for each environment
resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  count                                = var.dms_replication_instance.subnet_group_id == null ? 1 : 0
  replication_subnet_group_description = "Subnet group for DMS replication instances"
  replication_subnet_group_id          = var.dms_replication_instance.subnet_group_name == null ? "${data.aws_region.current.name}-${var.environment}" : var.dms_replication_instance.subnet_group_name
  # these would come from the core stack once created
  subnet_ids = var.dms_replication_instance.subnet_ids

  tags = merge(var.tags,
    {
      Name        = "${data.aws_region.current.name}-${var.environment}"
      application = "Data Engineering"
    }
  )
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
  replication_subnet_group_id  = var.dms_replication_instance.subnet_group_id == null ? aws_dms_replication_subnet_group.replication_subnet_group[0].id : var.dms_replication_instance.subnet_group_id
  vpc_security_group_ids       = [aws_security_group.replication_instance.id]

  tags = merge({ Name = var.dms_replication_instance.replication_instance_id },
    var.tags
  )
}
