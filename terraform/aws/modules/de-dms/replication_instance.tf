resource "aws_dms_replication_subnet_group" "replication_subnet_group" {
  replication_subnet_group_description = "Subnet group for DMS replication instances"
  replication_subnet_group_id          = "${data.aws_region.current.name}-${var.environment}"

  # these would come from the core stack once created
  subnet_ids = var.dms_replication_subnet_ids

  tags = {
    Name = "${data.aws_region.current.name}-${var.environment}"
  }
}
